#datalakedeletefile
type DataLakeDeleteFileRequest
    DataStoreName::String
    TableName::String
    FilePath::String
end
function delete_datalake_file!(datastorename::String,tablename::String,filename_including_partition::String)
    table_def=get_table_definition(storename=datastorename,tablename=tablename)
    schematype=filter(tuple->last(tuple)==table_def.SchemaType,collect(schema_type_map))[1][1]
    folderpath=lowercase("/managed/$schematype/table/$tablename/")
    request=DataLakeDeleteFileRequest(datastorename,tablename,folderpath*strip(filename_including_partition,'/'))
    NeuroJulia.neurocall("8080","DataMovementService","DataLakeDeleteFile",request)
    return nothing
end
#listdatalaketablefiles
type ListDataLakeTableFilesRequest
    DataStoreName::String
    TableName::String
end

function listdatalaketablefileswithpartitions(datastorename::String,tablename::String)
    request=ListDataLakeTableFilesRequest(datastorename,tablename)
    files=NeuroJulia.neurocall("8080","DataMovementService","ListDataLakeTableFiles",request)["Files"]
    return [split(files[i],tablename)[2] for i=1:length(files)]
end
