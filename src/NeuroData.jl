"""
    Streams:
        Functions:
            - stream(source,sink) returns StreamResponse
            - getdatatypes
        Source types:
            - SqlSourceParameters
            - CsvNotebookFileShareSourceParameters 
            - CsvDataLakeSourceParameters 
            - ExternalSqlSourceParameters 
        Sink types:
            - SqlSinkParameters 
            - CsvNotebookFileShareSinkParameters 
            - CsvDataLakeSinkParameters 
    Sql commands:
        Functions:
            - sqltodf(datastorename::String,sqlquery::SqlQuery)
            - sqltocsv(datastorename::String,sqlquery::SqlQuery,filename::String,folderpathfromroot::Union{String,Void}=nothing)
            - sqltransformation(datastorename::String,sqlquery::SqlQuery,sinktablename::String)
            - sqldeleterows!(datastorename::String,tablename::String,whereclause=nothing)
        Types:
            - SqlQuery
            - SqlJoin
    Datalake commands:
        Functions:
            - deletedatalakefile!(datastorename::String,tablename::String,filepath::String)
            - listdatalaketablefiles(datastorename::String,tablename::String)
    Schema manager commands:
        Functions:
            - create_destination_table(;storename::String=nothing,tabledefinition::DestinationTableDefinition=nothing)
            - get_table_definition(;storename::String=nothing,tablename::String=nothing)
            - add_destination_table_indexes(;storename::String=nothing,tablename::String=nothing,tableindexes::Array{DestinationTableDefinitionIndex,1}=nothing)
            - save_table_definition(;tabledefinition::DestinationTableDefinition=nothing,filename::String=nothing)
            - load_table_definition(;filename::String=nothing)
            - create_table_mapping(;storename=nothing,tablename=nothing,mappingname=nothing,notmapped=Array{String,1}(),source_dest_name_pairs=Array{Tuple{String,String}}(0))
"""

module NeuroData
    using NeuroJulia
    using DataFrames
    using JSON
    using CSV
    
    include(Pkg.dir() * "/NeuroJulia/src/NeuroData/NeuroDataTypes.jl")
    include(Pkg.dir() * "/NeuroJulia/src/NeuroData/NeuroDataSqlQuery.jl")
    include(Pkg.dir() * "/NeuroJulia/src/NeuroData/NeuroDataSourceSink.jl")
    include(Pkg.dir() * "/NeuroJulia/src/NeuroData/NeuroDataStream.jl")
    include(Pkg.dir() * "/NeuroJulia/src/NeuroData/NeuroDataSqlCommands.jl")
    include(Pkg.dir() * "/NeuroJulia/src/NeuroData/NeuroDataDatalakeCommands.jl")
    include(Pkg.dir() * "/NeuroJulia/src/NeuroData/NeuroDataSchemaManager.jl")
end
