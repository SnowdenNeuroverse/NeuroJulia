#-----------Sql-------------------
"""
    function SqlSourceParameters(datastorename::String,tablename::String)
"""
type SqlSourceParameters <: AbstractSourceParameters
    DataStoreName::String
    TableName::String
end

"""
    function SqlSinkParameters(datastorename::String,tablename::String;expressions::Union{Array{String,1},Void}=nothing,whereclause::Union{String,Void}=nothing)
"""
type SqlSinkParameters <: AbstractSinkParameters
    DataStoreName::String
    TableName::String
    Expressions::Union{Array{String,1},Void}
    WhereClause::Union{String,Void}
    function SqlSinkParameters(datastorename,tablename;expressions=nothing,whereclause=nothing)
        new(datastorename,tablename,expressions,whereclause)
    end
end

function sinktosource(sink::SqlSinkParameters,response::AbstractStreamResponse)::SqlSourceParameters
    return SqlSourceParameters(sink.DataStoreName,sink.TableName)
end

#-----------NotebookCsv----------------
"""
    function CsvNotebookFileShareSourceParameters(filename::String,datastartrow::Int,headers::Array{String,1},types::Array{String,1})
    Source and Sink data types can be found through NeuroData.getdatatypes()
"""
type CsvNotebookFileShareSourceParameters <: AbstractSourceParameters
    FileName::String
    DataStartRow::Int
    Headers::Array{String,1}
    Types::Array{String,1}
    function CsvNotebookFileShareSourceParameters(filename,datastartrow,headers,types)
        filename=pwd()*"/"*strip(filename,'/')
        new(filename,datastartrow,headers,types)
    end
end

"""
    function CsvNotebookFileShareSinkParameters(filename::String,headers::Array{String,1},types::Array{String,1};expressions::Union{Array{String,1},Void}=nothing,whereclause::Union{String,Void}=nothing)
    Source and Sink data types can be found through NeuroData.getdatatypes()
"""
type CsvNotebookFileShareSinkParameters <: AbstractSinkParameters
    FileName::String
    Headers::Array{String,1}
    Types::Array{String,1}
    Expressions::Union{Array{String,1},Void}
    WhereClause::Union{String,Void}
    function CsvNotebookFileShareSinkParameters(filename,headers,types;expressions=nothing,whereclause=nothing)
        filename=pwd()*"/"*strip(filename,'/')
        new(filename,headers,types,expressions,whereclause)
    end
end

function sinktosource(sink::CsvNotebookFileShareSinkParameters,response::AbstractStreamResponse)::CsvNotebookFileShareSourceParameters
    return CsvNotebookFileShareSourceParameters(sink.FileName,2,sink.Headers,sink.Types)
end

#----------DataLakeCsv-----------------
"""
    function CsvDataLakeSourceParameters(datastorename::String,tablename::String,filename::String,datastartrow::String)
"""
type CsvDataLakeSourceParameters <: AbstractSourceParameters
    DataStoreName::String
    TableName::String
    FileName::String
    DataStartRow::Int
end

"""
    function CsvDataLakeSinkParameters(datastorename::String,tablename::String,folderpath::String;expressions::Union{Array{String,1},Void}=nothing,whereclause::Union{String,Void}=nothing)
"""
type CsvDataLakeSinkParameters <: AbstractSinkParameters
    DataStoreName::String
    TableName::String
    FolderPath::String
    Expressions::Union{Array{String,1},Void}
    WhereClause::Union{String,Void}
    function CsvDataLakeSinkParameters(datastorename,tablename,folderpath;expressions=nothing,whereclause=nothing)
        new(datastorename,tablename,folderpath,expressions,whereclause)
    end
end

function sinktosource(sink::CsvDataLakeSinkParameters,response::AbstractStreamResponse)::CsvDataLakeSourceParameters
    fileName=sink.FolderPath * "/" * response.JobId * "_" * replace(replace(response.TimeStamp,":","-"),".","-") * ".csv"
    return CsvDataLakeSourceParameters(sink.DataStoreName,sink.TableName,fileName,1)
end

#----------ExternalSql-------------
"""
    function ExternalSqlSourceParameters(tablename::String,connectionstring::String)
"""
type ExternalSqlSourceParameters <: AbstractSourceParameters
    TableName::String
    ConnectionString::String
end
