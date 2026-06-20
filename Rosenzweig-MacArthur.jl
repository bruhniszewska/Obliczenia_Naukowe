using CSV
using DataFrames
using Plots
using DifferentialEquations
using Optimization
using OptimizationOptimJL
using SciMLLogging
using ForwardDiff 

sciezka_do_pliku = joinpath(@__DIR__, "isle-royale.csv")

lata = Float64.(dane.year)
ofiary_realne = Float64.(dane.moose)        
drapiezniki_realne = Float64.(dane.wolves)  
lata = Float64.(dane.year)
ofiary_realne = Float64.(dane.moose)
drapiezniki_realne = Float64.(dane.wolves)


function zaawansowany_model!(du, u, p, t)
    x, y = u          
    r, K, a, D, e, m = p    
    #łosie
    du[1] = r * x * (1.0 - x / K) - (a * x / (D + x)) * y
    #wilki
    du[2] = e * (a * x / (D + x)) * y - m * y
end


u0 = [ofiary_realne[1], drapiezniki_realne[1]]
tspan = (lata[1], lata[end])


function funkcja_straty(p, _)

    if any(p .<= 0.0)
        return 1e12
    end

    prob = ODEProblem(zaawansowany_model!, u0, tspan, p)
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


p_start = [0.6, 2200.0, 15.0, 600.0, 0.08, 0.35]

opt_funkcja = OptimizationFunction(funkcja_straty, Optimization.AutoForwardDiff())
opt_prob = OptimizationProblem(opt_funkcja, p_start)

wynik = solve(opt_prob, BFGS())
p_opt = wynik.u

println("\n=== WYZNACZONE PARAMETRY OPTYMALNE ===")
println("r (przyrost łosi):           ", round(p_opt[1], digits=4))
println("K (pojemność środowiska):    ", round(p_opt[2], digits=1))
println("a (max tempo ataku wilka):   ", round(p_opt[3], digits=4))
println("D (stała nasycenia Hollinga):", round(p_opt[4], digits=1))
println("e (współczynnik rozrodu):    ", round(p_opt[5], digits=4))
println("m (śmiertelność wilków):     ", round(p_opt[4], digits=4))

t_smooth = range(lata[1], lata[end], length=400)
prob_opt = ODEProblem(zaawansowany_model!, u0, tspan, p_opt)
sol_gładka = solve(prob_opt, Tsit5(), saveat=t_smooth, reltol=1e-6, abstol=1e-6, verbose=SciMLLogging.None())



p1 = plot(lata, ofiary_realne, 
          label="Dane: Rzeczywista liczebność", color=:blue, lw=1.2, marker=:circle, markersize=5,
          grid=true, frame=:box)
plot!(t_smooth, [sol_gładka(t)[1] for t in t_smooth], 
      label="Model: Rosenzweig-MacArthur", color=:blue, lw=2.5, linestyle=:dash)
ylabel!("Liczba osobników (Łosie)")
title!("Populacja Ofiar (Łosie)")


p2 = plot(lata, drapiezniki_realne, 
          label="Dane: Rzeczywista liczebność", color=:orange, lw=1.2, marker=:square, markersize=5,
          grid=true, frame=:box)
plot!(t_smooth, [sol_gładka(t)[2] for t in t_smooth], 
      label="Model: Rosenzweig-MacArthur", color=:orange, lw=2.5, linestyle=:dash)
ylabel!("Liczba osobników (Wilki)")
xlabel!("Rok")
title!("Populacja Drapieżników (Wilki)")

wykres_porownawczy = plot(p1, p2, layout=(2,1), size=(850, 650),
                          plot_title="Konfrontacja surowych danych z zaawansowanym modelem ekologicznym",
                          plot_titlefont=font(11, "Arial Bold"))


display(wykres_porownawczy)
savefig(wykres_porownawczy, "wykres_rosenzweig_macarthur.png")
