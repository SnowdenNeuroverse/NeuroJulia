abstract type AbstractSourceParameters end
abstract type AbstractSinkParameters end
abstract type AbstractStreamRequest end
abstract type AbstractStreamResponse end

function getdatatypes()
    return ["Boolean","Int32","Int64","Decimal","Double","DateTime","Guid","String"]
end
