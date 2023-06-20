# SOLVE OPTIMIZATION PROBLEM

function solveOptimizationProblem(InputParameters::InputParam, SolverParameters::SolverParam, Battery::BatteryParam)

    @unpack (NYears, NMonths, NStages, NSteps, Big, NHoursStep, NHoursStage) = InputParameters;
    @unpack (max_Charge, max_Discharge, energy_Capacity, Eff_charge, Eff_discharge, max_SOH ) = Battery;

    println("Solving Optimization Problem")

    objective = 0
    revenues_per_stage = zeros(NStages)

    charge = zeros(NSteps)
    discharge = zeros(NSteps)
    soc = zeros(NSteps)

    cumulative_energy = zeros(NStages)
    eq_cycles = zeros(NStages)
    degradation = zeros(NStages)

    soh_final = zeros(NStages)
    soh_initial = zeros(NStages)

    problem = BuildStageProblem(InputParameters, SolverParameters, Battery)

    @timeit to "Solve optimization" optimize!(problem.M)

    if termination_status(problem.M) != MOI.OPTIMAL
        println("NOT OPTIMAL: ", termination_status(problem.M))
    end

    @timeit to "Collecting results" begin
        objective = JuMP.objective_value(problem.M)
        
        for iStep=1:NSteps
            soc[iStep] = JuMP.value(problem.soc[iStep])
            charge[iStep] = JuMP.value(problem.charge[iStep])
            discharge[iStep] = JuMP.value(problem.discharge[iStep])
        end

        for iStage=1:NStages
            cumulative_energy[iStage] = JuMP.value(problem.A[iStage])
            eq_cycles[iStage] = JuMP.value(problem.Ncycle[iStage])
            degradation[iStage] = JuMP.value(problem.deg[iStage])
            soh_final[iStage] = JuMP.value(problem.soh_final[iStage])
            soh_initial[iStage] = JuMP.value(problem.soh_new[iStage])
        
        end

        for iStage=2:(NStages-1)
            revenues_per_stage[iStage] = sum(Power_prices[iStep]*NHoursStep*(discharge[iStep]-charge[iStep]) for iStep=((iStage-1)*NHoursStage+1):(NHoursStage*iStage)) - Battery_price[iStage]*(soh_initial[iStage+1]-soh_final[iStage])
        end
          
        revenues_per_stage[1] = sum(Power_prices[iStep]*NHoursStep*(discharge[iStep]-charge[iStep]) for iStep=((1-1)*NHoursStage+1):(NHoursStage*1)) - Battery_price[1]*(soh_initial[1])
        revenues_per_stage[NStages] = sum(Power_prices[iStep]*NHoursStep*(discharge[iStep]-charge[iStep]) for iStep=((NStages-1)*NHoursStage+1):(NHoursStage*NStages)) + Battery_price[NStages]*(soh_final[NStages])

    end

    println("Optimization finished")

    return Results(
        objective,
        revenues_per_stage,
        charge,
        discharge,
        soc,
        cumulative_energy,
        eq_cycles,
        degradation,
        soh_final,
        soh_initial,
    )

end