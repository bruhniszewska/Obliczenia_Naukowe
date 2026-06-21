# struktury.jl
using Random

struct SimParams
    K_local::Int64    
    p_pass::Float64   
    r_prey::Float64   
    alpha::Float64    
    d_pred::Float64   
end

mutable struct GridState
    prey::Matrix{Int64}
    pred::Matrix{Int64}
    pred_energy::Matrix{Float64} 
    terrain::Matrix{Int64} 
end

println("Struktury załadowane.")