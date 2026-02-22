module Utils

function set_temperatures(
    β_min, 
    β_max; 
    M=15, 
    method=:geometric
)
    if method == :geometric
        if β_min == 0
            β_min = 1e-2  # Avoid division by zero
        end
        return [β_max * (β_min / β_max)^((M - i)/(M - 1)) for i in 1:M]
    elseif method == :inverse_linear
        return [β_min + (β_max - β_min) * (i - 1)/(M - 1) for i in 1:M]
    else
        @error "Unknown method for temperatures"
    end
end

function β2D(β)
    return diff(β)
end

function β2logD(β)
    Δβ = diff(β)
    return log.(Δβ)
end

# function D2β(D, β_1)
#     return cumsum([β_1; D])
# end

function D2β(D, β_M)
    β_1 = β_M - sum(D)
    return cumsum([β_1; D])
end

function logD2β(log_D, β_min, β_max)
    M = length(log_D) + 2
    temp_range = β_max - β_min
    
    Δβ = exp.(log_D)
    Δβ_M_1 = temp_range - sum(Δβ)
    if Δβ_M_1 <= 0.0 
        Δβ_M_1 = 1e-12
        @warn "Constraint Violated! Δβ_{M-1} calculated as $Δβ_M_1. Clipping to minimum."
    end
    Δβ_full = [Δβ; Δβ_M_1]

    β_set = zeros(M) 
    β_set[M] = β_max
    
    for k in (M-1):-1:1
        Δβ_k = Δβ_full[k]
        β_set[k] = β_set[k+1] - Δβ_k
    end
    β_set[1] = β_min 

    return β_set
end

export set_temperatures, β2D, β2logD, D2β, logD2β

end