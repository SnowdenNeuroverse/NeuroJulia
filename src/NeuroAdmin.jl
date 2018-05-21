module NeuroAdmin
    using NeuroJulia
    using DataFrames

    function getactivenotebooksessions()
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
    function getendpointlog(endpointName,startDate,endDate;maxDisplayRows=200)
        endPointResultEnvelope = NeuroJulia.neurocall("8080","endpointmanagementservice","GetEndpoints",nothing)
        endpointId = ""
        for endpoint in endPointResultEnvelope["EndPointInfo"]
            if endpoint["Name"] == endpointName
                endpointId = endpoint["EndPointId"]
            end
        end
        request = Dict("EndpointId"=>endpointId,"MessageTypeId"=> "", "EndDate"=>endDate, "StartDate"=>startDate)
        resultEnvelope = NeuroJulia.neurocall("8080","endpointmanagementservice","GetMonitorLogEntries",request)
        return resultEnvelope["DataIngestionLogEntries"]
    end
end
