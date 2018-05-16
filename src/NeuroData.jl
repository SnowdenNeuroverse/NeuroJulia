module NeuroData
    using NeuroJulia
    using DataFrames
    using JSON
    using CSV
    
    abstract type AbstractSqlQuery end
    abstract type AbstractSqlJoin end
    
    """
        Parameters:
        select::String,tablename::String,subquery::AbstractSqlQuery,alias::String,
            joins::Array{AbstractSqlJoin,1},where::String,groupby::String,having::String,orderby::String
        Required:
        select
        tablename or subquery
        Notes:
        If a join is supplied an alias must be supplied
    """
    type SqlQuery <: AbstractSqlQuery
        SourceMappingType::Int
        SelectClause::String
        FromTableName::Union{String,Void}
        FromSubQuery::Union{AbstractSqlQuery,Void}
        FromAlias::Union{String,Void}
        Joins::Union{Array{AbstractSqlJoin,1},Void}
        WhereClause::Union{String,Void}
        GroupByClause::Union{String,Void}
        HavingClause::Union{String,Void}
        OrderByClause::Union{String,Void}
        function SqlQuery(;select::String=nothing,tablename::Union{String,Void}=nothing,subquery::Union{AbstractSqlQuery,Void}=nothing,
            alias::Union{String,Void}=nothing,
            joins::Union{Array{AbstractSqlJoin,1},Void}=nothing,where::Union{String,Void}=nothing,groupby::Union{String,Void}=nothing,
            having::Union{String,Void}=nothing,orderby::Union{String,Void}=nothing)
            return new(1,select,tablename,subquery,alias,joins,where,groupby,having,orderby)
        end
    end


    """
        Parameters:
        jointype::String,tablename::String,subquery::AbstractSqlQuery,alias::String,clause::String
        Required:
        jointype
        tablename or subquery
        alias
        clause
    """
    type SqlJoin <: AbstractSqlJoin
        JoinType::String
        JoinTableName::Union{String,Void}
        JoinSubQuery::Union{AbstractSqlQuery,Void}
        JoinAlias::String
        JoinClause::String
        function SqlJoin(;jointype::String=nothing,tablename::String=nothing,subquery::AbstractSqlQuery=nothing,alias::String=nothing,clause::String=nothing)
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
        StoreName::String
    end

    function sqltofileshare(transferfromsqltofilesharerequest)
        service = "datamovementservice"
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
    """
        sqltocsv(;storename::String=val1,sqlquery::SqlQuery=val2,filename::String=val3)
        sqltocsv(;storename::String=val1,sqlquery::SqlQuery=val2,folderpath::String=val3,filename::String=val4)
    """
    function sqltocsv(;storename::String=nothing,sqlquery::SqlQuery=nothing,folderpath::Union{String,Void}=nothing,filename::String=nothing)
        fs=DestinationFolder(folderpath)
        folder=NeuroJulia.homedir * fs.FolderPath
        if isfile(folder * filename)
            error("File exists: " * folder * filename)
        end
        tr = TransferFromSqlToFileShareRequest(fs,sqlquery,storename)
        outputname=sqltofileshare(tr)
        mv(folder * outputname, folder * filename)
        return folder * filename
    end

    "sqltodf(;storename::String=val1,sqlquery::SqlQuery=val2)"
    function sqltodf(;storename::String=nothing,sqlquery::SqlQuery=nothing)
        fs=DestinationFolder(nothing)
        tr = TransferFromSqlToFileShareRequest(fs,sqlquery,storename)
        outputname=sqltofileshare(tr)
        folder=NeuroJulia.homedir * fs.FolderPath
        file=open(folder * outputname)
        str=readline(file)
        tmp=split(str,",")
        headers=String[replace(tmp[col],"\0","") for col=1:length(tmp)]
        close(file)
        df=[]
        try
            df=CSV.read(folder * outputname,header=headers,datarow=2)
        catch
            error("Table has no data")
        end
        rm(folder * outputname)
        return df
    end

    data_type_map=Dict{String,Int}("Int"=>11,"Decimal"=>9,"String"=>14,"BigInt"=>1,"Boolean"=>3,"DateTime"=>6,"UniqueIdentifier"=>22)
    col_type_map=Dict{String,Int}("Key"=>1,"Value"=>4,"TimeStampKey"=>3,"ForeignKey"=>2)

    """
    Parameters:
    indexname::String,indexcolumnnames::Array{String,1}
    Required:
    indexname
    indexcolumnnames
    """
    type DestinationTableDefinitionIndex
        IndexName::String
        #ColumnName:____
        IndexColumns::Array{Dict{String,String},1}
        function DestinationTableDefinitionIndex(;indexname::String=nothing,indexcolumnnames::Array{String,1}=nothing)
            cols=Array{Dict{String,String}}(0)
            for col in indexcolumnnames
                push!(cols,Dict("ColumnName"=>col))
            end
            new(indexname,cols)
        end
    end
    
    """
    Parameters:
    name::String,datatype::String,columntype::String,isrequired::Bool=false
    Required:
    name
    datatype
    columntype
    """
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
        ForeignKeyTableName
        ForeignKeyColumnName
        Index::Int
        function DestinationTableDefinitionColumn(;name::String=nothing,datatype::String=nothing,columntype::String=nothing,isrequired::Bool=false)
            col=new()
            col.ColumnDataTypePrecision=nothing
            col.ColumnDataTypeScale=nothing
            col.ColumnDataTypeSize=nothing
            col.ForeignKeyTableName=nothing
            col.ForeignKeyColumnName=nothing

            col.ColumnName=name
        
            if contains(columntype,"ForeignKey")
                col.ColumnType=col_type_map["ForeignKey"]
                col.ForeignKeyTableName=split(columntype,['(',')',','])[2]
                col.ForeignKeyColumnName=split(columntype,['(',')',','])[3]
            else
                col.ColumnType=col_type_map[columntype]
            end

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
            else
                col.ColumnDataType=data_type_map[datatype]
            end 
            return col
        end
    end

    """
    Parameters:
    allowdatachanges::Bool=false,columns::Array{DestinationTableDefinitionColumn,1},
    name::String,tableindexes::Array{DestinationTableDefinitionIndex,1},
    schematype::String,schematypeid::Int
    Required:
    name
    columns
    schematype or schematypeid
    """
    type DestinationTableDefinition
        AllowDataLossChanges::Bool
        #CreatedBy::String
        #CreatedDate::String
        DestinationTableDefinitionColumns::Array{DestinationTableDefinitionColumn,1}
        DestinationTableDefinitionIndexes::Array{DestinationTableDefinitionIndex,1}
        DestinationTableName::String
        #LastChangedBy::String
        #LastChangedDate::String
        #MappingsCount::Int
        #SchemaError::Bool
        #StorageType::Int
        DataStoreId::Union{String,Void}
        SchemaType::Int
        function DestinationTableDefinition(;allowdatachanges::Bool=false,columns::Array{DestinationTableDefinitionColumn,1}=nothing,
            name::String=nothing,tableindexes::Union{Array{DestinationTableDefinitionIndex,1},Void}=nothing,
            schematype::Union{String,Void}=nothing,schematypeid::Union{Int,Void}=nothing)
            for ind=1:length(columns)
                columns[ind].Index=ind
            end
            if schematypeid==nothing
                if schematype=="Data Ingestion"
                    schematypeid=1
                elseif schematype=="Time Series"
                    schematypeid=2
                elseif schematype=="Processed"
                    schematypeid=3
                else
                    error("schematype must be \"Data Ingestion\", \"Time Series\" or \"Processed\"")
                end
            end
            datastoreid=nothing
            indexes=DestinationTableDefinitionIndex[]
            if tableindexes!=nothing
                indexes=tableindexes
            end
           return new(allowdatachanges,columns,indexes,name,datastoreid,schematypeid) 
        end
    end

    "create_destination_table(;storename::String=val1,tabledefinition::DestinationTableDefinition=val2)"
    function create_destination_table(;storename::String=nothing,tabledefinition::DestinationTableDefinition=nothing)
        datastoreid=""
        try
            datastoreid=NeuroJulia.neurocall("80","datastoremanager","GetDataStores",Dict("StoreName"=>storename))["DataStores"][1]["DataStoreId"]
        catch
            error("Data Store name is not valid")
        end

        table_def.DataStoreId=datastoreid
        NeuroJulia.neurocall("datapopulationservice","CreateDestinationTableDefinition",tabledefinition)
    end

    type GetDestinationTableDefinitionRequest
        TableName
        DataStoreId
    end

    "get_table_definition(;storename::String=val1,tablename::String=val2)"
    function get_table_definition(;storename::String=nothing,tablename::String=nothing)
        datastoreid=nothing
        try
            datastoreid=NeuroJulia.neurocall("80","datastoremanager","GetDataStores",Dict("StoreName"=>storename))["DataStores"][1]["DataStoreId"]
        catch
            error("Data Store name is not valid")
        end
        request=GetDestinationTableDefinitionRequest(tablename,datastoreid)
        table_def=NeuroJulia.neurocall("DataPopulationService","GetDestinationTableDefinition",request)
        cols=NeuroData.DestinationTableDefinitionColumn[]
        for col in table_def["DestinationTableDefinitions"][1]["DestinationTableDefinitionColumns"]
            if col["ColumnName"]!="NeuroverseLastModified"
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
        indexes=DestinationTableDefinitionIndex[]
        for ind in table_def["DestinationTableDefinitions"][1]["DestinationTableDefinitionIndexes"]
            push!(indexes,DestinationTableDefinitionIndex(;indexname=ind["IndexName"],indexcolumns=[ind["IndexColumns"][i]["ColumnName"] for i = 1:length(ind["IndexColumns"])]))
        end
    
        schematypeid=table_def["DestinationTableDefinitions"][1]["SchemaType"]
    
        schematype=""
        if schematypeid==1
            schematype="Data Ingestion"
        elseif schematypeid==2
            schematype="Time Series"
        elseif schematypeid==3
            schematype="Processed"
        end
    
        new_table_def=NeuroData.DestinationTableDefinition(allowdatachanges=table_def["DestinationTableDefinitions"][1]["AllowDataLossChanges"],
        columns=cols,name=table_def["DestinationTableDefinitions"][1]["DestinationTableName"],tableindexes=indexes,schematype=schematype)
        return new_table_def
    end

    "add_destination_table_indexes(;storename::String=val1,tablename::String=val2,tableindexes::Array{DestinationTableDefinitionIndex,1}=val3)"
    function add_destination_table_indexes(;storename::String=nothing,tablename::String=nothing,tableindexes::Array{DestinationTableDefinitionIndex,1}=nothing)
        datastoreid=nothing
        try
            datastoreid=NeuroJulia.neurocall("80","datastoremanager","GetDataStores",Dict("StoreName"=>storename))["DataStores"][1]["DataStoreId"]
        catch
            error("Data Store name is not valid")
        end    
        request=GetDestinationTableDefinitionRequest(tablename,datastoreid)
        table_def=NeuroJulia.neurocall("DataPopulationService","GetDestinationTableDefinition",request)["DestinationTableDefinitions"][1]
        append!(table_def["DestinationTableDefinitionIndexes"],JSON.parse(JSON.json(tableindexes)))
        NeuroJulia.neurocall("datapopulationservice","UpdateDestinationTableDefinition",table_def)
    end

    "save_table_definition(;tabledefinition::DestinationTableDefinition=val1,filename::String=val2)"
    function save_table_definition(;tabledefinition::DestinationTableDefinition=nothing,filename::String=nothing)
        def=JSON.json(tabledef)
        file=open(filename,"w+")
        write(file,def)
        close(file)
    end

    "load_table_definition(;filename::String=val1)"
    function load_table_definition(;filename::String=nothing)
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
        indexes=DestinationTableDefinitionIndex[]
        for ind in table_def["DestinationTableDefinitionIndexes"]
            push!(indexes,DestinationTableDefinitionIndex(;indexname=ind["IndexName"],indexcolumns=[ind["IndexColumns"][i]["ColumnName"] for i = 1:length(ind["IndexColumns"])]))
        end
    
        datastoreid=table_def["DataStoreId"]
        schematypeid=table_def["SchemaType"]
    
        new_table_def=NeuroData.DestinationTableDefinition(allowdatachanges=table_def["AllowDataLossChanges"],
        columns=cols,name=table_def["DestinationTableName"],tableindexes=indexes,schematypeid=schematypeid)
        new_table_def.DataStoreId=datastoreid
        return new_table_def
    end

    type DataPopulationMappingSourceColumn
        DestinationColumnInfo::Dict{String,Any}
        DestinationColumnName::String
        IsMapped::Bool
        SourceColumnName::String
    end

    type DataPopulationMappingRequest
        DataPopulationMappingSourceColumns
        DestinationTableDefinitionId
        MappingName
        function DataPopulationMappingRequest(tableId,columns,mappingname)
            new(columns,tableId,mappingname)
        end
    end

    function create_table_mapping(;storename=nothing,tablename=nothing,mappingname=nothing,notmapped=Array{String,1}(),source_dest_name_pairs=Array{Tuple{String,String}}(0))
        if storename==nothing
            error("Supply data store name")
        end
        datastoreid=nothing
        try
            datastoreid=NeuroJulia.neurocall("80","datastoremanager","GetDataStores",Dict("StoreName"=>storename))["DataStores"][1]["DataStoreId"]
        catch
            error("Data Store name is not valid")
        end    
        request=GetDestinationTableDefinitionRequest(tablename,datastoreid)
        table_def=NeuroJulia.neurocall("DataPopulationService","GetDestinationTableDefinition",request)
        columns=NeuroData.DataPopulationMappingSourceColumn[]
        for col in table_def["DestinationTableDefinitions"][1]["DestinationTableDefinitionColumns"]
            if col["ColumnName"]!="NeuroverseLastModified"
                if findfirst(notmapped,col["ColumnName"])==0
                    ismapped=true
                    destcolumnname=col["ColumnName"]
                    sourcecolumnname=destcolumnname
                    if length(source_dest_name_pairs)>0
                       tmp_ind=findfirst(map(x->x[2],source_dest_name_pairs),destcolumnname)
                        if tmp_ind>0
                            sourcecolumnname=source_dest_name_pairs[findfirst(map(x->x[2],source_dest_name_pairs),destcolumnname)][1]
                        end
                    end

                    push!(columns,NeuroData.DataPopulationMappingSourceColumn(
                    col,destcolumnname,ismapped,sourcecolumnname))
                end
            end
        end

        data=NeuroData.DataPopulationMappingRequest(table_def["DestinationTableDefinitions"][1]["DestinationTableDefinitionId"],columns,mappingname)
        NeuroJulia.neurocall("DataPopulationService","CreateDataPopulationMapping",data)
    end

end
