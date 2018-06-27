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
        rm(NeuroJulia.homedir * csvfile)
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
        folderpathfromroot=replace(strip(pwd(),'/')*"/",strip(NeuroJulia.homedir,'/'),"")
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
    check_request=Dict("JobId"=>response["JobId"])

    status=0
    errormsg=""
    while(status==0)
        sleep(1)
        response_c=NeuroJulia.neurocall("8080","DataMovementService","CheckJob",check_request)
        status=response_c["Status"]
        if status>1
            errormsg=response_c["Message"]
        end
    end
    
    NeuroJulia.neurocall("8080","DataMovementService","FinaliseJob",check_request)

    if status!=1
        error("Neuroverse error: " * errormsg)
    end
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
    check_request=Dict("JobId"=>response["JobId"])

    status=0
    errormsg=""
    while(status==0)
        sleep(1)
        response_c=NeuroJulia.neurocall("8080","DataMovementService","CheckJob",check_request)
        status=response_c["Status"]
        if status>1
            errormsg=response_c["Message"]
        end
    end
    
    NeuroJulia.neurocall("8080","DataMovementService","FinaliseJob",check_request)

    if status!=1
        error("Neuroverse error: " * errormsg)
    end
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
    check_request=Dict("JobId"=>response["JobId"])

    status=0
    errormsg=""
    while(status==0)
        sleep(1)
        response_c=NeuroJulia.neurocall("8080","DataMovementService","CheckJob",check_request)
        status=response_c["Status"]
        if status>1
            errormsg=response_c["Message"]
        end
    end
    
    NeuroJulia.neurocall("8080","DataMovementService","FinaliseJob",check_request)

    if status!=1
        error("Neuroverse error: " * errormsg)
    end
    return nothing
end
