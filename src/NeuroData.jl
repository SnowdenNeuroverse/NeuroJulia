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
                jsondata = open(filepath)
                d = JSON.parse(readstring(jsondata))
                if d["Error"] == nothing
                    keeplooping=false
                else
                    close(jsondata)
                    rm(filepath)
                    error("Neuroverse error: " * d["Error"])
                end
                close(jsondata)
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

    data_type_map=Dict{String,Int}("Int"=>11,"Decimal"=>9,"String"=>14,"BigInt"=>1,"Boolean"=>3,"DateTime"=>6,"UniqueIdentifier"=>22)
    col_type_map=Dict{String,Int}("Key"=>1,"Value"=>4,"TimeStampKey"=>3,"ForeignKey"=>2)

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
        ForeignKeyTableName::String
        ForeignKeyColumnName::String
        Index::Int
        function DestinationTableDefinitionColumn(;name="",datatype="",columntype="",isrequired=false)
            col=new()
            col.ColumnDataTypePrecision=nothing
            col.ColumnDataTypeScale=nothing
            col.ColumnDataTypeSize=nothing
            col.ForeignKeyTableName=nothing
            col.ForeignKeyColumnName=nothing

            col.ColumnName=name
            col.ColumnType=col_type_map[columntype]

            col.IsRequired=isrequired
            col.IsSystemColumn=false
            col.ValidationError=""
            col.WasRemoved=false

            if contains(datatype,"String")
                col.ColumnDataType=data_type_map["String"]
                col.ColumnDataTypeSize=parse(split(datatype,['(',')',','])[2])
            elseif contains(datatype,"Decimal")
                col.ColumnDataType=data_type_map["Decimal"]
                col.ColumnDataTypePrecision=parse(split(datatype,['(',')',','])[2])
                col.ColumnDataTypeScale=parse(split(datatype,['(',')',','])[3])
            elseif contains(datatype,"ForeignKey")
                col.ColumnDataType=data_type_map["ForeignKey"]
                col.ForeignKeyTableName=split(datatype,['(',')',','])[2]
                col.ForeignKeyColumnName=split(datatype,['(',')',','])[3]
            else
                col.ColumnDataType=data_type_map[datatype]
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
        function DestinationTableDefinition(;allowdatachanges=false,columns=nothing,
            name=nothing)
            for ind=1:length(columns)
                columns[ind].Index=ind
            end
            CreateDate=string(Dates.now())
            CreatedBy=NeuroJulia.neurocall("security","getSamsLicenses",nothing)["UserInfo"]["UserId" ]
           return new(allowdatachanges,CreatedBy,CreateDate,columns,DestinationTableDefinitionIndex[],name,CreatedBy,CreateDate,0,false,1) 
        end
    end

    function create_destination_table(table_def::DestinationTableDefinition)
        NeuroJulia.neurocall("datapopulation","CreateDestinationTableDefinition",table_def)
    end

    type GetDestinationTableDefinitionRequest
        TableName
    end

    function get_table_definition(;tablename=nothing)
        request=GetDestinationTableDefinitionRequest(tablename)
        table_def=NeuroJulia.neurocall("DataPopulation","GetDestinationTableDefinition",request)
        cols=NeuroData.DestinationTableDefinitionColumn[]
        for col in table_def["DestinationTableDefinitions"][1]["DestinationTableDefinitionColumns"]
            if col["ColumnName"]!="LastUpdated"
                tmp_col=NeuroData.DestinationTableDefinitionColumn(name=col["ColumnName"],
                        datatype="Int",
                        columntype="Value",
                        isrequired=col["IsRequired"])

                tmp_col.ColumnDataTypeScale=col["ColumnDataTypeScale"]
                tmp_col.ColumnDataType=col["ColumnDataType"]
                tmp_col.ColumnDataTypePrecision=col["ColumnDataTypePrecision"]
                tmp_col.ColumnDataTypeSize=col["ColumnDataTypeSize"]
                tmp_col.ColumnType=col["ColumnType"]
                push!(cols,tmp_col)
            end
        end
        cols
        new_table_def=NeuroData.DestinationTableDefinition(allowdatachanges=table_def["DestinationTableDefinitions"][1]["AllowDataLossChanges"],
        columns=cols,name=table_def["DestinationTableDefinitions"][1]["DestinationTableName"])
        return new_table_def
    end

    function save_table_definition(;tabledef=nothing,filename=nothing)
        def=JSON.json(tabledef)
        file=open(filename,"w+")
        write(file,def)
        close(file)
    end

    function load_table_definition(;filename=nothing)
        file=open(filename)
        table_def=JSON.parse(readstring(file))
        close(file)
        cols=NeuroData.DestinationTableDefinitionColumn[]
        for col in table_def["DestinationTableDefinitionColumns"]
            tmp_col=NeuroData.DestinationTableDefinitionColumn(name=col["ColumnName"],
                    datatype="Int",
                    columntype="Value",
                    isrequired=col["IsRequired"])

            tmp_col.ColumnDataTypeScale=col["ColumnDataTypeScale"]
            tmp_col.ColumnDataType=col["ColumnDataType"]
            tmp_col.ColumnDataTypePrecision=col["ColumnDataTypePrecision"]
            tmp_col.ColumnDataTypeSize=col["ColumnDataTypeSize"]
            tmp_col.ColumnType=col["ColumnType"]
            push!(cols,tmp_col)
        end
        cols
        new_table_def=NeuroData.DestinationTableDefinition(allowdatachanges=table_def["AllowDataLossChanges"],
        columns=cols,name=table_def["DestinationTableName"])
    end
end
