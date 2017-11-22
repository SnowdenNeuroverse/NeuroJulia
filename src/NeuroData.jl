module NeuroData
    using NeuroJulia
    using DataFrames

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
        filepath = homedir * transferfromsqltofilesharerequest.FileShareDestinationDefinition.FolderPath
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
        folder=homedir * fs.FolderPath
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
        folder=homedir * fs.FolderPath
        df = readtable(folder * outputname)
        rm(folder * outputname)
        return df
    end
end
