abstract type AbstractSourceParameters end
abstract type AbstractSinkParameters end

#-----------Sql-------------------
type SqlSourceParameters <: AbstractSourceParameters
    DataStoreName::String
    TableName::String
end

function Sink2Source(sink::SqlSinkParameters,response::StreamResponse)::SqlSourceParameters
    return SqlSourceParameters(sink.DataStoreName,sink.TableName)
end

type SqlSinkParameters <: AbstractSinkParameters
    DataStoreName::String
    TableName::String
    Expressions::Union{Array{String,1},Void}
    WhereClause::Union{String,Void}
    function SqlSinkParameters(datastorename,tablename,expressions=nothing,whereclause=nothing)
        new(datastorename,tablename,expressions,whereclause)
    end
end

#-----------NotebookCsv----------------
type CsvNotebookFileShareSourceParameters <: AbstractSourceParameters
    FileName::String
    DataStartRow::Int
    Headers::Array{String,1}
    Types::Array{String,1}
end

function Sink2Source(sink::CsvNotebookFileShareSinkParameters,response::StreamResponse)::CsvNotebookFileShareSourceParameters
    return CsvNotebookFileShareSourceParameters(sink.FileName,2,sink.Headers,sink.Types)
end

type CsvNotebookFileShareSinkParameters <: AbstractSinkParameters
    FileName::String
    Headers::Array{String,1}
    Types::Array{String,1}
    Expressions::Union{Array{String,1},Void}
    WhereClause::Union{String,Void}
    function CsvNotebookFileShareSinkParameters(filename,headers,types,expressions=nothing,whereclause=nothing)
        new(filename,headers,types,expressions,whereclause)
    end
end

#----------DataLakeCsv-----------------
type CsvDataLakeSourceParameters <: AbstractSourceParameters
    DataStoreName::String
    TableName::String
    FileName::String
    DataStartRow::Int
end

function Sink2Source(sink::CsvDataLakeSinkParameters,response::StreamResponse)::CsvDataLakeSourceParameters
    fileName=sink.FolderPath * "/" * response.JobId * "_" * replace(replace(response.TimeStamp,":","-"),".","-") * ".csv"
    return CsvDataLakeSourceParameters(sink.DataStoreName,sink.TableName,fileName,1)
end

type CsvDataLakeSinkParameters <: AbstractSinkParameters
    DataStoreName::String
    TableName::String
    FolderPath::String
    Expressions::Union{Array{String,1},Void}
    WhereClause::Union{String,Void}
    function CsvDataLakeSinkParameters(datastorename,tablename,folderpath,expressions=nothing,whereclause=nothing)
        new(datastorename,tablename,folderpath,expressions,whereclause)
    end
end

#----------ExternalSql-------------
type ExternalSqlSourceParameters <: AbstractSourceParameters
    TableName::String
    ConnectionString::String
end
