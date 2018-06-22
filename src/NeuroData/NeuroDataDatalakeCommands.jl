#datalakedeletefile
type DataLakeDeleteFileRequest
    DataStoreName::String
    TableName::String
    FilePath::String
end
function delete_datalake_file!(datastorename::String,tablename::String,filename_including_partition::AbstractString)
    table_def=get_table_definition(storename=datastorename,tablename=tablename)
    schematype=filter(tuple->last(tuple)==table_def.SchemaType,collect(schema_type_map))[1][1]
    folderpath=lowercase("/managed/$schematype/table/$tablename/")
    request=DataLakeDeleteFileRequest(datastorename,tablename,folderpath*strip(filename_including_partition,'/'))
    response=NeuroJulia.neurocall("8080","DataMovementService","DataLakeDeleteFile",request)
    sleep(1)
    while NeuroJulia.neurocall("8080","DataMovementService","CheckJob",Dict("JobId"=>response["JobId"]))["Status"]==0
        sleep(1)
    end
    NeuroJulia.neurocall("8080","DataMovementService","FinaliseJob",Dict("JobId"=>response["JobId"]))
    return nothing
end
#listdatalaketablefiles
type ListDataLakeTableFilesRequest
    DataStoreName::String
    TableName::String
end

function list_datalake_table_files_with_partitions(datastorename::String,tablename::String)
    request=ListDataLakeTableFilesRequest(datastorename,tablename)
    files=NeuroJulia.neurocall("8080","DataMovementService","ListDataLakeTableFiles",request)["Files"]
    return [split(files[i],lowercase(tablename))[2] for i=1:length(files)]
end
