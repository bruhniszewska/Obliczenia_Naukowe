#funkcja obliczeniowa
function get_local_prey_density(prey::Matrix{Int64}, i::Int, j::Int, rows::Int, cols::Int)::Int
    count = 0
    for dj in -2:2, di in -2:2
        ni, nj = i + di, j + dj
        if (1 <= ni <= rows) && (1 <= nj <= cols)
            @inbounds count += prey[ni, nj]
        end
    end
    return count
end

function update_sim!(next_state::GridState, curr_state::GridState, p::SimParams)
    R, C = size(curr_state.prey)
    fill!(next_state.prey, 0)
    fill!(next_state.pred, 0)
    fill!(next_state.pred_energy, 0.0)
    
    
    for j in 1:C
        for i in 1:R
            @inbounds pr = curr_state.prey[i, j]
            @inbounds pd = curr_state.pred[i, j]
            @inbounds pe = curr_state.pred_energy[i, j]
            
            if pr > 0 || pd > 0
                local_density = get_local_prey_density(curr_state.prey, i, j, R, C)
                is_overpopulated = local_density > p.K_local
                
                eaten = 0
                if pr > 0 && pd > 0
                    chance = p.alpha * pd
                    eaten = rand(0:min(pr, round(Int, chance * pr + 0.5)))
                end
                
                next_pr = pr - eaten
                next_pd = pd
                
                if pd > 0
                    energy_gain = eaten * 0.75
                    energy_loss = pd * p.d_pred
                    new_energy = max(0.0, pe + energy_gain - energy_loss)
                    
                    while new_energy >= 1.0
                        next_pd += 1
                        new_energy -= 1.0
                    end
                    
                    if new_energy == 0.0 && next_pd > 0
                        next_pd = max(0, next_pd - rand(1:2))
                    end
                    pe = new_energy
                else
                    pe = 0.0
                end
                
                if next_pr > 0
                    eff_r = is_overpopulated ? p.r_prey * 0.05 : p.r_prey
                    next_pr += rand(0:round(Int, eff_r * next_pr + 0.2))
                end
                
                if next_pd == 0 && rand() < 0.002
                    next_pd = rand(1:2)
                    pe = 0.5
                end
                
                if next_pr > 0
                    for _ in 1:next_pr
                        step_range = is_overpopulated ? (-2:2) : (-1:1)
                        ni, nj = i + rand(step_range), j + rand(step_range)
                        if (1 <= ni <= R) && (1 <= nj <= C)
                            @inbounds is_river = curr_state.terrain[ni, nj] == 1
                            if !is_river || (rand() < p.p_pass)
                                @inbounds next_state.prey[ni, nj] += 1
                            else
                                @inbounds next_state.prey[i, j] += 1
                            end
                        else
                            @inbounds next_state.prey[i, j] += 1
                        end
                    end
                end
                
                if next_pd > 0
                    for _ in 1:next_pd
                        ni, nj = i + rand(-1:1), j + rand(-1:1)
                        if (1 <= ni <= R) && (1 <= nj <= C)
                            @inbounds next_state.pred[ni, nj] += 1
                            @inbounds next_state.pred_energy[ni, nj] += pe / next_pd
                        else
                            @inbounds next_state.pred[i, j] += 1
                            @inbounds next_state.pred_energy[i, j] += pe / next_pd
                        end
                    end
                end
            end
        end
    end
end