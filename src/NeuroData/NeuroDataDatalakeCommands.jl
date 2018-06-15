#datalakedeletefile
type DataLakeDeleteFileRequest
    DataStoreName::String
    TableName::String
    FilePath::String
end
function deletedatalakefile!(datastorename::String,tablename::String,filepath::String)
    request=DataLakeDeleteFileRequest(datastorename,tablename,filepath)
    NeuroJulia.neurocall("8080","DataMovementService","DataLakeDeleteFile",request)
    return nothing
end
#listdatalaketablefiles
type ListDataLakeTableFilesRequest
    DataStoreName::String
    TableName::String
end

function listdatalaketablefiles(datastorename::String,tablename::String)
    request=ListDataLakeTableFilesRequest(datastorename,tablename)
    return NeuroJulia.neurocall("8080","DataMovementService","ListDataLakeTableFiles",request)["Files"]
end