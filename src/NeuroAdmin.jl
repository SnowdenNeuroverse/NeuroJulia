module NeuroAdmin
    using NeuroJulia
    using DataFrames

    function getactivesessions()
        service = "notebookmanagementservice"
        method = "getdetailedsessionlist"
        requestbody=nothing
        response = NeuroJulia.neurocall(service,method,requestbody)
        if response["Error"] != nothing
            error("Neuroverse Error: " * response["Error"])
        end
        df = DataFrame()
        df[:Host] = response["SessionList"]["Host"]
        df[:Session_User] = response["SessionList"]["Session User"]
        df[:Session_Id] = response["SessionList"]["Session Id"]
        df[:Session_CPU] = response["SessionList"]["Session CPU"]
        df[:Session_Memory] = response["SessionList"]["Session Memory"]
        df[:Session_TmpStorage] = response["SessionList"]["Session Temporary Storage"]
        return df
    end
end
