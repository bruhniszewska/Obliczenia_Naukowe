using DelimitedFiles

function run_rk4(p, u0, t_max::Float64, dt::Float64, t_points_set)
    r, K, α, b, d = p
    
    f(u) = [
        r * u[1] * (1.0 - u[1] / K) - α * u[1] * u[2],
        b * u[1] * u[2] - d * u[2]
    ]
    
    n_steps = round(Int, t_max / dt)
    u = copy(u0)
    
    results = Dict{Float64, Vector{Float64}}()
    results[0.0] = copy(u)
    
    for i in 1:n_steps
        k1 = f(u)
        k2 = f(u + 0.5 * dt * k1)
        k3 = f(u + 0.5 * dt * k2)
        k4 = f(u + dt * k3)
        u = u + (dt / 6.0) * (k1 + 2*k2 + 2*k3 + k4)
        
        current_t = round(i * dt, digits=2)
        
        if current_t in t_points_set
            results[current_t] = copy(u)
        end
    end
    return results
end

function loss_function(p, t_points, t_points_set, data_prey_sym, data_pred_sym)
    r, K, α, d = p  
    
    if r < 0.05 || r > 0.5 return Inf end
    if K < 2000 || K > 35000 return Inf end
    if α <= 0 return Inf end
    if d < 0.01 || d > 0.70 return Inf end 
    
    b = 0.75 * α 
    full_p = [r, K, α, b, d]
    
    u0 = [data_prey_sym[1], data_pred_sym[1]]
    t_max_val = Float64(maximum(t_points)) 
    
    rk4_results = run_rk4(full_p, u0, t_max_val, 0.1, t_points_set)
    
    total_error = 0.0
    for (i, t) in enumerate(t_points)
        if haskey(rk4_results, t)
            pred_rk4 = rk4_results[t]
            total_error += (pred_rk4[1] - data_prey_sym[i])^2
            total_error += (pred_rk4[2] - data_pred_sym[i])^2
        end
    end
    return total_error
end

function calibrate_parameters(history_points_time_prey, history_points_time_pred)
    punkty_zajace = history_points_time_prey[]
    punkty_wilki  = history_points_time_pred[]

    data_prey_sym = [Float64(p[2]) for p in punkty_zajace]
    data_pred_sym = [Float64(p[2]) for p in punkty_wilki]
    t_points = [Float64(p[1]) for p in punkty_zajace] 
    t_points_set = Set(t_points) 

    best_p = [0.25, (100 / 25) * 6400, 0.20 / 6400, 0.08] 
    best_loss = loss_function(best_p, t_points, t_points_set, data_prey_sym, data_pred_sym)
    
    for iter in 1:2000 
        test_p = best_p .* (1.0 .+ (rand(4) .- 0.5) .* 0.02) 
        test_loss = loss_function(test_p, t_points, t_points_set, data_prey_sym, data_pred_sym)
        
        if test_loss < best_loss
            best_loss = test_loss
            best_p = test_p
        end
    end
    
    r_fin, K_fin, α_fin, d_fin = best_p
    b_fin = 0.75 * α_fin
    
    final_vector = [r_fin, K_fin, α_fin, b_fin, d_fin]
    println("Zoptymalizowany błąd: ", best_loss)
    println("Prawidłowe parametry [r, K, α, b, d]: ", final_vector)
    return final_vector
end

println("Moduł kalibracji załadowany.")

