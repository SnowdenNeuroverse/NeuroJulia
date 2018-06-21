data_type_map=Dict{String,Int}("Int"=>11,"Decimal"=>9,"String"=>14,"BigInt"=>1,"Boolean"=>3,"DateTime"=>6,"UniqueIdentifier"=>22,
"Int32"=>11,"Int64"=>1,"Double"=>10,"Guid"=>22)
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
function DestinationTableDefinition(;allowdatachanges::Bool=false,columns::Array{DestinationTableDefinitionColumn,1}=nothing,
        name::String=nothing,tableindexes::Union{Array{DestinationTableDefinitionIndex,1},Void}=nothing,
        schematype::Union{String,Void}=nothing,schematypeid::Union{Int,Void}=nothing,partitionpath::Union{String,Void}=nothing)
Required:
name
columns
schematype or schematypeid
"""
type DestinationTableDefinition
    DestinationTableDefinitionId::String
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
    FilePath::Union{String,Void}
    function DestinationTableDefinition(;allowdatachanges::Bool=false,columns::Array{DestinationTableDefinitionColumn,1}=nothing,
        name::String=nothing,tableindexes::Union{Array{DestinationTableDefinitionIndex,1},Void}=nothing,
        schematype::Union{String,Void}=nothing,schematypeid::Union{Int,Void}=nothing,partitionpath::Union{String,Void}=nothing)
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
       return new(allowdatachanges,columns,indexes,name,datastoreid,schematypeid,partitionpath) 
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

    tabledefinition.DataStoreId=datastoreid
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
        push!(indexes,DestinationTableDefinitionIndex(;indexname=ind["IndexName"],indexcolumnnames=[ind["IndexColumns"][i]["ColumnName"] for i = 1:length(ind["IndexColumns"])]))
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
    table_def.DestinationTableDefinitionId=table_def["DestinationTableDefinitions"][1]["DestinationTableDefinitionId"]
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
    def=JSON.json(tabledefinition)
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
        push!(indexes,DestinationTableDefinitionIndex(;indexname=ind["IndexName"],indexcolumnnames=[ind["IndexColumns"][i]["ColumnName"] for i = 1:length(ind["IndexColumns"])]))
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

"create_processed_table!(datastorename::String,tablename::String,columnnames::Array{String,1},columntypes::Array{String,1};partitionpath::Union{String,Void}=nothing)"
function create_processed_table!(datastorename::String,tablename::String,columnnames::Array{String,1},columntypes::Array{String,1};partitionpath::Union{String,Void}=nothing)
    schematype="Processed"
    
    columns=NeuroData.DestinationTableDefinitionColumn[]
    for col=1:length(columnnames)
        push!(columns,NeuroData.DestinationTableDefinitionColumn(;name=columnnames[col],datatype=columntypes[col],columntype="Value",isrequired=true))
    end

    table_def=NeuroData.DestinationTableDefinition(;allowdatachanges=false,columns=columns,
            name=tablename,schematype=schematype,partitionpath=partitionpath)

    NeuroData.create_destination_table(storename=datastorename,tabledefinition=table_def)
end
"delete_processed_table!(datastorename::String,tablename::String)"
function delete_processed_table!(datastorename::String,tablename::String)
    table_def=get_table_definition(storename=datastorename,tablename=tablename)
    if table_def.SchemaType!=3
        error("Table schema type is not processed")
    end
    NeuroJulia.neurocall("DataPopulationService","DeleteDestinationTableDefinition",Dict("DestinationTableDefinitionId"=>table_def.DestinationTableDefinitionId))
end
    
