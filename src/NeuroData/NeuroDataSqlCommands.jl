#sql2df
function sqltodf(datastorename::String,sqlquery::SqlQuery)
    if !isdir(NeuroJulia.homedir*"tmp")
        mkdir(NeuroJulia.homedir*"tmp")
    end
    filename=string(Base.Random.uuid1())
    folderpathfromroot="tmp"
    csvfile=sqltocsv(datastorename,sqlquery,filename,folderpathfromroot)
    df=[]
    try
        df=CSV.read(NeuroJulia.homedir * csvfile)
    catch
        error("Table has no data")
    end
    
    rm(NeuroJulia.homedir * csvfile)
    return df
end

#sql2csv
type SqlQueryToCsvNotebookFileShareRequest
    SqlParameters
    FileName::String
end
function sqltocsv(datastorename::String,sqlquery::SqlQuery,filename::String,folderpathfromroot::Union{String,Void}=nothing)
    if folderpathfromroot==nothing
        folderpathfromroot=replace(pwd()*"/",NeuroJulia.homedir,"")
    end
    if folderpathfromroot[1]=='/' || folderpathfromroot[1]=='\\'
        folderpathfromroot=folderpathfromroot[2:length(folderpathfromroot)]
    end
    if folderpathfromroot[length(folderpathfromroot)]!='/' && folderpathfromroot[length(folderpathfromroot)]!='\\'
        folderpathfromroot*="/"
    end
    folder=folderpathfromroot
    if isfile(NeuroJulia.homedir * folder * filename)
        error("File exists: " * folder * filename)
    end
    request=SqlQueryToCsvNotebookFileShareRequest(Dict("DataStoreName"=>datastorename,"SqlQuery"=>sqlquery),folder * filename)
    response=NeuroJulia.neurocall("8080","DataMovementService","SqlQueryToCsvNotebookFileShare",request)
    sleep(1)
    while NeuroJulia.neurocall("8080","DataMovementService","CheckJob",Dict("JobId"=>response["JobId"]))["Status"]==0
        sleep(1)
    end
    NeuroJulia.neurocall("8080","DataMovementService","FinaliseJob",Dict("JobId"=>response["JobId"]))
    return folder * filename
end

#sqltranformation
type SqlTransformationRequest
    SqlTransformationParameters
    SinkTableName::String
end
function sqltransformation(datastorename::String,sqlquery::SqlQuery,sinktablename::String)
    request=SqlTransformationRequest(Dict("DataStoreName"=>datastorename,"SqlQuery"=>sqlquery),sinktablename)
    response=NeuroJulia.neurocall("8080","DataMovementService","SqlTransformation",request)
    sleep(1)
    while NeuroJulia.neurocall("8080","DataMovementService","CheckJob",Dict("JobId"=>response["JobId"]))["Status"]==0
        sleep(1)
    end
    NeuroJulia.neurocall("8080","DataMovementService","FinaliseJob",Dict("JobId"=>response["JobId"]))
    return StreamResponse(response["JobId"],response["TimeStamp"])
end

#sqldelete
type SqlDeleteRequest
    DataStoreName::String
    TableName::String
    WhereClause::Union{String,Void}
end
function sqldeleterows!(datastorename::String,tablename::String;whereclause=nothing)
    request=SqlDeleteRequest(datastorename,tablename,whereclause)
    response=NeuroJulia.neurocall("8080","DataMovementService","SqlDelete",request)
    sleep(1)
    while NeuroJulia.neurocall("8080","DataMovementService","CheckJob",Dict("JobId"=>response["JobId"]))["Status"]==0
        sleep(1)
    end
    NeuroJulia.neurocall("8080","DataMovementService","FinaliseJob",Dict("JobId"=>response["JobId"]))
    return nothing
end
