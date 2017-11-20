module NeuroJulia
    export NeuroData
    include(Pkg.dir() * "/NeuroJulia/src/NeuroData.jl")
    using NeuroData

end # module
