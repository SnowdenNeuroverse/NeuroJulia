module NeuroJulia
    export NeuroData,NeuroAdmin
    include(Pkg.dir() * "/NeuroJulia/src/NeuroData.jl")
    include(Pkg.dir() * "/NeuroJulia/src/NeuroAdmin.jl")
end # module
