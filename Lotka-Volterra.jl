using CSV
using DataFrames
using Plots
using DifferentialEquations
using Optimization
using OptimizationOptimJL
using SciMLLogging
using ForwardDiff 


sciezka_do_pliku = joinpath(@__DIR__, "isle-royale.csv")

dane = CSV.read(sciezka_do_pliku, DataFrame)


lata = Float64.(dane.year)
ofiary_realne = Float64.(dane.moose)       
drapiezniki_realne = Float64.(dane.wolves)  

lata = Float64.(dane.year)
ofiary_realne = Float64.(dane.moose)
drapiezniki_realne = Float64.(dane.wolves)

function lotka_volterra!(du, u, p, t)
    x, y = u          
    α, β, δ, γ = p    
    du[1] = α*x - β*x*y
    du[2] = δ*x*y - γ*y
end

u0 = [ofiary_realne[1], drapiezniki_realne[1]]
tspan = (lata[1], lata[end])


function funkcja_straty(p, _)
    if any(p .<= 0.0)
        return 1e12
    end

    prob = ODEProblem(lotka_volterra!, u0, tspan, p)
    sol = solve(prob, Tsit5(), saveat=lata, reltol=1e-4, abstol=1e-4, verbose=SciMLLogging.None())
    
    if sol.retcode != ReturnCode.Success || any(isnan, sol) || any(isinf, sol)
        return 1e12
    end
    
    x_teoria = [sol(t)[1] for t in lata]
    y_teoria = [sol(t)[2] for t in lata]

    if any(x_teoria .<= 0.1) || any(y_teoria .<= 0.1)
        return 1e12
    end


    blad_ofiar = sum((log.(x_teoria) .- log.(ofiary_realne)).^2)
    blad_drap = sum((log.(y_teoria) .- log.(drapiezniki_realne)).^2)
    
    return blad_ofiar + blad_drap
end

p_start = [0.5, 0.02, 0.0001, 0.2]

opt_funkcja = OptimizationFunction(funkcja_straty, Optimization.AutoForwardDiff())
opt_prob = OptimizationProblem(opt_funkcja, p_start)

wynik = solve(opt_prob, BFGS())
p_opt = wynik.u

println("\n=== WYZNACZONE PARAMETRY OPTYMALNE ===")
println("Alfa  (przyrost łosi):        ", round(p_opt[1], digits=4))
println("Beta  (skuteczność wilków):   ", round(p_opt[2], digits=4))
println("Delta (rozród wilków):        ", round(p_opt[3], digits=5))
println("Gamma (śmiertelność wilków):  ", round(p_opt[4], digits=4))


prob_opt = ODEProblem(lotka_volterra!, u0, tspan, p_opt)
t_smooth = range(lata[1], lata[end], length=400)
sol_gładka = solve(prob_opt, Tsit5(), saveat=t_smooth, reltol=1e-6, abstol=1e-6, verbose=SciMLLogging.None())



p1 = plot(t_smooth, [sol_gładka(t)[1] for t in t_smooth], 
          label="Model: Łosie (teoria)", color=:blue, lw=2.5, linestyle=:dash,
          grid=true)
scatter!(lata, ofiary_realne, 
         label="Dane: Łosie (Real)", color=:blue, markersize=5, markerstrokewidth=1)
ylabel!("Populacja Łosi")
title!("Populacja Ofiar (Łosie)")

p2 = plot(t_smooth, [sol_gładka(t)[2] for t in t_smooth], 
          label="Model: Wilki (teoria)", color=:orange, lw=2.5,
          grid=true)
scatter!(lata, drapiezniki_realne, 
         label="Dane: Wilki (Real)", color=:orange, markersize=5, markershape=:square)
ylabel!("Populacja Wilków")
xlabel!("Rok") 
title!("Populacja Drapieżników (Wilki)")


wykres_finalny = plot(p1, p2, layout=(2,1), size=(800, 600), 
                      plot_title="Model Lotki-Volterry dopasowany do danych Isle Royale", 
                      plot_titlefont=font(12, "Arial Bold"))

display(wykres_finalny)
savefig(wykres_finalny, "wykres_lotka_volterra.png")
