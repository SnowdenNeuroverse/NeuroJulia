module NeuroJulia
    export NeuroData,NeuroAdmin

    using JSON
    using Requests
    using MbedTLS

    global token = ENV["JUPYTER_TOKEN"]
    global domain = ENV["NV_DOMAIN"]
    domain = if contains(domain,"prd")
        #"https://neuroverse.com.au"
        "https://15ded47f-ef38-4ee3-b989-685820ca3d36.cloudapp.net"
    elseif contains(domain,"tst")
        "https://launchau.snowdenonline.com.au"
    elseif contains(domain,"sit")
        "https://neurosit.snowdenonline.com.au"
    elseif contains(domain,"dev")
        "https://neurodev.snowdenonline.com.au"
    else
        "http://localhost"
    end
    global homedir = "/home/jovyan/session/"


    prepo = LibGit2.GitRepo(abspath(Pkg.dir(), "NeuroJulia"))
    phead = LibGit2.head(prepo)
    global branchname = LibGit2.shortname(phead)

    function neurocall(port,service,method,requestbody;timeout=1200)
        url = domain * ":8080/NeuroApi/" * port * "/" * service * "/api/" * replace(lowercase(service),"service","") * "/" * method
        if domain=="http://localhost"
            url = domain * ":8082/NeuroApi/" * port * "/" * service * "/api/" * replace(lowercase(service),"service","") * "/" * method
        end
        msgdata = nothing
        msgdatalength = 0
        if requestbody!=nothing
            msgdata = JSON.json(requestbody)
            msgdatalength = length(msgdata)
        end
        headers = Dict("Content-Length" => string(msgdatalength), "Token" => token, "Accept" => "application/json", "Content-Type" => "application/json")
        response = post(url; headers=headers, data=msgdata, timeout=timeout, tls_conf=MbedTLS.SSLConfig(false))
        if response.status != 200
            if response.status == 401
                error("Session has expired: Log into Neuroverse and connect to your Notebooks session or reload the Notebooks page in Neuroverse")
            elseif response.status == 404
                error(replace(lowercase(service),"service","") * "/" * method * " does not exist")
            else
                error("Neuroverse connection error: Http code " * string(response.status))
            end
        end
        file = open("testoutput.txt","a+")
        write(file,msgdata)
        write(file,"\n")
        close(file)
        responseobj = JSON.parse(readstring(response))
        if responseobj["Error"] != nothing
            error("Neuroverse Error: " * responseobj["Error"])
        end
        return responseobj
    end


    function neurocall(service,method,requestbody;timeout=1200)
        url = domain * ":8080/NeuroApi/8080/" * service * "/api/" * replace(lowercase(service),"service","") * "/" * method
        if domain=="http://localhost"
            url = domain * ":8082/NeuroApi/8080/" * service * "/api/" * replace(lowercase(service),"service","") * "/" * method
        end
        msgdata = nothing
        msgdatalength = 0
        if requestbody!=nothing
            msgdata = JSON.json(requestbody)
            msgdatalength = length(msgdata)
        end
        headers = Dict("Content-Length" => string(msgdatalength), "Token" => token, "Accept" => "application/json", "Content-Type" => "application/json")
        response = post(url; headers=headers, data=msgdata, timeout=timeout, tls_conf=MbedTLS.SSLConfig(false))
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
        run(`curl https://raw.githubusercontent.com/SnowdenNeuroverse/NeuroNotebooks/$branchname/Notebooks/$filename --output $output`)
    end

    include(Pkg.dir() * "/NeuroJulia/src/NeuroData.jl")
    include(Pkg.dir() * "/NeuroJulia/src/NeuroAdmin.jl")
end # module
