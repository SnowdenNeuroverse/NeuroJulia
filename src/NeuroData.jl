module NeuroData
    using NeuroJulia
    using DataFrames
    using JSON

    type SqlQuery
        SourceMappingType
        SelectClause
        FromTableName
        FromSubQuery
        FromAlias
        Joins
        WhereClause
        GroupByClause
        HavingClause
        OrderByClause
        function SqlQuery(;select=nothing,tablename=nothing,subquery=nothing,alias=nothing,joins=nothing,where=nothing,groupby=nothing,having=nothing,orderby=nothing)
            return new(1,select,tablename,subquery,alias,joins,where,groupby,having,orderby)
        end
    end

    type SqlJoin
        JoinType
        JoinTableName
        JoinSubQuery
        JoinAlias
        JoinClause
        function SqlJoin(;jointype=nothing,tablename=nothing,subquery=nothing,alias=nothing,clause=nothing)
            return new(jointype,tablename,subquery,alias,clause)
        end
    end

    type DestinationFolder
        DestinationMappingType
        FolderPath
        function DestinationFolder(folderpath)
            if folderpath != nothing
                folderpath=strip(folderpath)
                startswith(folderpath,['/','\\']) ? folderpath = folderpath[2:length(folderpath)] : nothing
                !endswith(folderpath,['/','\\']) ? folderpath = folderpath * "/" : nothing
            else
                folderpath = ""
            end
            return new(0,folderpath)
        end
    end

    type TransferFromSqlToFileShareRequest
        FileShareDestinationDefinition::DestinationFolder
        SqlSourceDefinition::SqlQuery
    end

    function sqltofileshare(transferfromsqltofilesharerequest)
        service = "datamovement"
        method = "TransferFromSqlToFileShare"
        responseobj = NeuroJulia.neurocall(service,method,transferfromsqltofilesharerequest)
        if responseobj["Error"] != nothing
            error("Neuroverse Error: " * responseobj["Error"])
        end
        filepath = NeuroJulia.homedir * transferfromsqltofilesharerequest.FileShareDestinationDefinition.FolderPath
        filepath = filepath * responseobj["FileName"] * ".info"

        keeplooping=true
        while keeplooping
            if isfile(filepath)
                sleep(0.25)
                open(filepath) do jsondata
                    d = JSON.parse(readstring(jsondata))
                    if d["Error"] == nothing
                        keeplooping=false
                    else
                        error("Neuroverse error: " * d["Error"])
                    end
                end
            end
            sleep(0.25)
        end
        rm(filepath)
        return responseobj["FileName"]
    end

    function sqltocsv(;folderpath=nothing,filename=nothing,sqlquery=nothing)
        fs=DestinationFolder(folderpath)
        folder=NeuroJulia.homedir * fs.FolderPath
        if isfile(folder * filename)
            error("File exists: " * folder * filename)
        end
        tr = TransferFromSqlToFileShareRequest(fs,sqlquery)
        outputname=sqltofileshare(tr)
        mv(folder * outputname, folder * filename)
        return folder * filename
    end

    function sqltodf(;sqlquery=nothing)
        fs=DestinationFolder(nothing)
        tr = TransferFromSqlToFileShareRequest(fs,sqlquery)
        outputname=sqltofileshare(tr)
        folder=NeuroJulia.homedir * fs.FolderPath
        df = readtable(folder * outputname)
        rm(folder * outputname)
        return df
    end

    data_type_map=Dict{String,Int}("Int"=>11,"Decimal"=>9,"String"=>14)
    col_type_map=Dict{String,Int}("Key"=>1,"Value"=>4)

    type DestinationTableDefinitionIndex
        Index::Int
    end

    type DestinationTableDefinitionColumn
        ColumnDataType::Int
        ColumnName::String
        ColumnType::Int
        IsRequired::Bool
        IsSystemColumn::Bool
        ValidationError::String
        WasRemoved::Bool
        ColumnDataTypePrecision
        ColumnDataTypeScale
        ColumnDataTypeSize
        Index::Int
        function DestinationTableDefinitionColumn(;ColumnName="",ColumnDataType="",ColumnType="",IsRequired=false)
            col=new()
            col.ColumnDataTypePrecision=nothing
            col.ColumnDataTypeScale=nothing
            col.ColumnDataTypeSize=nothing

            col.ColumnName=ColumnName
            col.ColumnType=col_type_map[ColumnType]
            col.IsRequired=IsRequired
            col.IsSystemColumn=false
            col.ValidationError=""
            col.WasRemoved=false

            if contains(ColumnDataType,"Int")
                col.ColumnDataType=data_type_map["Int"]
            elseif contains(ColumnDataType,"String")
                col.ColumnDataType=data_type_map["String"]
                col.ColumnDataTypeSize=parse(split(ColumnDataType,['(',')',','])[2])
            elseif contains(ColumnDataType,"Decimal")
                col.ColumnDataType=data_type_map["Decimal"]
                col.ColumnDataTypePrecision=parse(split(ColumnDataType,['(',')',','])[2])
                col.ColumnDataTypeScale=parse(split(ColumnDataType,['(',')',','])[3])
            end 
            return col
        end
    end

    type DestinationTableDefinition
        AllowDataLossChanges::Bool
        CreatedBy::String
        CreatedDate::String
        DestinationTableDefinitionColumns::Array{DestinationTableDefinitionColumn,1}
        DestinationTableDefinitionIndexes::Array{DestinationTableDefinitionIndex,1}
        DestinationTableName::String
        LastChangedBy::String
        LastChangedDate::String
        MappingsCount::Int
        SchemaError::Bool
        StorageType::Int
        function DestinationTableDefinition(;AllowDataLossChanges=false,DestinationTableDefinitionColumns=nothing,
            DestinationTableName=nothing, DestinationTableDefinitionIndexes=DestinationTableDefinitionIndex[])
            for ind=1:length(DestinationTableDefinitionColumns)
                DestinationTableDefinitionColumns[ind].Index=ind
            end
            CreateDate=string(Dates.now())
            CreatedBy=NeuroJulia.neurocall("security","getSamsLicenses",nothing)["UserInfo"]["UserId" ]
           return new(AllowDataLossChanges,CreatedBy,CreateDate,DestinationTableDefinitionColumns,DestinationTableDefinitionIndexes,DestinationTableName,CreatedBy,CreateDate,0,false,1) 
        end
    end

    function CreateDestinationTableDefinition(table_def::DestinationTableDefinition)
        NeuroJulia.neurocall("datapopulation","CreateDestinationTableDefinition",table_def)
    end
end
