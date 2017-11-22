module NeuroAdmin
    using JSON
    using Requests
    using DataFrames

    global token = ENV["JUPYTER_TOKEN"]
    global domain = ENV["NV_DOMAIN"] * ":8082/NeuroApi/"

    function neurocall(method_address,requestbody)
        url = domain * method_address
        msgdata = nothing
        msgdatalength = 0
        if requestbody!=nothing
            msgdata = JSON.json(requestbody)
            msgdatalength = length(msgdata)
        end
        headers = Dict("Content-Length" => string(msgdatalength), "Token" => token)
        response = post(url; headers=headers, data=msgdata)
        if response.status != 200
            if response.status == 401
                error("Session has expired: Log into Neuroverse and connect to your Notebooks session or reload the Notebooks page in Neuroverse")
            else
                error("Neuroverse connection error: Http code " * string(response.status))
            end
        end
        responseobj = JSON.parse(readstring(response))
        if responseobj["Error"] != nothing
            error("Neuroverse Error: " * responseobj["Error"])
        end
        return responseobj
    end

    function getactivesessions()
        method_address="notebookmanagementservice/api/getdetailedsessionlist/"
        requestbody=nothing
        response = neurocall(method_address,requestbody)
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
