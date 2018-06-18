type StreamRequest <: AbstractStreamRequest
    SourceParameters::AbstractSourceParameters
    SinkParameters::AbstractSinkParameters
end

type StreamResponse <: AbstractStreamResponse
    JobId::String
    TimeStamp::String
end

function stream(source::AbstractSourceParameters,sink::AbstractSinkParameters)::StreamResponse
    request=StreamRequest(source,sink)

    sourcelist=split(string(typeof(source)),'.')
    sourcename=replace(sourcelist[length(sourcelist)],"SourceParameters","")
    
    sinklist=split(string(typeof(sink)),'.')
    sinkname=replace(sinklist[length(sinklist)],"SinkParameters","")
    
    method = sourcename * "To" * sinkname
    response = NeuroJulia.neurocall("8080","DataMovementService",method,request)
    
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
