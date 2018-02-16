module NeuroJulia
    export NeuroData,NeuroAdmin

    using JSON
    using Requests
    using MbedTLS

    global token = ENV["JUPYTER_TOKEN"]
    global domain = ENV["NV_DOMAIN"]
    domain = if contains(domain,"prd")
        "https://neuroverse.com.au"
    elseif contains(domain,"tst")
        "https://launchau.snowdenonline.com.au"
    elseif contains(domain,"sit")
        "https://neurosit.snowdenonline.com.au"
    else
        "https://neurodev.snowdenonline.com.au"
    end
    global homedir = "/home/jovyan/session/"

    function neurocall(service,method,requestbody)
        url = domain * ":8080/NeuroApi/" * service * "service/api/" * service * "/" * method
        msgdata = nothing
        msgdatalength = 0
        if requestbody!=nothing
            msgdata = JSON.json(requestbody)
            msgdatalength = length(msgdata)
        end
        headers = Dict("Content-Length" => string(msgdatalength), "Token" => token, "Accept" => "application/json", "Content-Type" => "application/json")
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

    function get_notebook(filename)
        directory=homedir * "00_NeuroTemplates"
        try
            run(`mkdir $directory`)
        end
        filename=split(filename,'.')[1] * ".ipynb"
        output=directory * "/" * split(filename,'.')[1] * "_" * replace(split(string(Dates.now()),'.')[1],':','_') * ".ipynb"
        run(`curl https://raw.githubusercontent.com/SnowdenNeuroverse/NeuroNotebooks/master/notebooks/$filename --output $output`)
    end

    include(Pkg.dir() * "/NeuroJulia/src/NeuroData.jl")
    include(Pkg.dir() * "/NeuroJulia/src/NeuroAdmin.jl")
end # module
