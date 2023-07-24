# SOLVE OPTIMIZATION PROBLEM

function solveOptimizationProblem(InputParameters::InputParam, SolverParameters::SolverParam, Battery::BatteryParam)

    @unpack (NYears, NMonths, NStages, NSteps, Big, NHoursStep, NHoursStage) = InputParameters;
    @unpack (energy_Capacity, Eff_charge, Eff_discharge, max_SOH, min_SOH, Nfull, max_disc ) = Battery;

    println("Solving Optimization Problem")

    objective = 0
    revenues_per_stage = zeros(NStages)
    gain_stage = zeros(NStages)
    cost_rev = zeros(NStages)
    deg_stage = zeros(NStages)

    charge = zeros(NSteps)
    discharge = zeros(NSteps)
    soc = zeros(NSteps+1)

    aux =zeros(NSteps)

    deg_neg = zeros(NSteps)
    deg_pos = zeros(NSteps)

    soh_final = zeros(NStages)
    soh_initial = zeros(NStages)
    

    problem = BuildStageProblem(InputParameters, SolverParameters, Battery)

    #unset_time_limit_sec(problem)
    @timeit to "Solve optimization" optimize!(problem.M)

    if termination_status(problem.M) != MOI.OPTIMAL
        println("NOT OPTIMAL: ", termination_status(problem.M))
    else
        println("Optimization finished")
    end

    @timeit to "Collecting results" begin
        objective = JuMP.objective_value(problem.M)
        
        for iStep=1:NSteps
            soc[iStep] = JuMP.value(problem.soc[iStep])
            charge[iStep] = JuMP.value(problem.charge[iStep])
            discharge[iStep] = JuMP.value(problem.discharge[iStep])

            aux[iStep] = JuMP.value(problem.auxiliary[iStep])
    
            deg_neg[iStep] = JuMP.value(problem.deg1[iStep])
            deg_pos[iStep] = JuMP.value(problem.deg2[iStep])

        end

        soc[end] = JuMP.value(problem.soc[end])

        for iStage=1:NStages
            soh_final[iStage] = JuMP.value(problem.soh_final[iStage])
            soh_initial[iStage] = JuMP.value(problem.soh_new[iStage])

            deg_stage[iStage] = sum(deg1[iStep]+deg2[iStep] for iStep=((iStage-1)*NHoursStage+1):(NHoursStage*iStage))*NHoursStep/(2*Nfull*energy_Capacity) 
        end

        #
        for iStage=2:(NStages-1)
            revenues_per_stage[iStage] = sum(Power_prices[iStep]*NHoursStep*(discharge[iStep]-charge[iStep]) for iStep=((iStage-1)*NHoursStage+1):(NHoursStage*iStage)) - Battery_price[iStage]*(soh_initial[iStage]-soh_final[iStage-1])
            gain_stage[iStage] = sum(Power_prices[iStep]*NHoursStep*(discharge[iStep]-charge[iStep]) for iStep=((iStage-1)*NHoursStage+1):(NHoursStage*iStage))
            cost_rev[iStage] = Battery_price[iStage]*(soh_initial[iStage]-soh_final[iStage-1])
        end
        #

        revenues_per_stage[1] = sum(Power_prices[iStep]*NHoursStep*(discharge[iStep]-charge[iStep]) for iStep=((1-1)*NHoursStage+1):(NHoursStage*1)) - Battery_price[1]*(soh_initial[1]-min_SOH)
        gain_stage[1]= sum(Power_prices[iStep]*NHoursStep*(discharge[iStep]-charge[iStep]) for iStep=((1-1)*NHoursStage+1):(NHoursStage*1))
        #cost_rev[1] = Battery_price[1]*(soh_initial[1]-min_SOH)-Battery_price[2]*(soh_final[1]-min_SOH)
        cost_rev[1] = Battery_price[1]*(soh_initial[1]-min_SOH)

        
        revenues_per_stage[NStages] = sum(Power_prices[iStep]*NHoursStep*(discharge[iStep]-charge[iStep]) for iStep=((NStages-1)*NHoursStage+1):(NHoursStage*NStages)) + Battery_price[NStages+1]*(soh_final[NStages]-min_SOH)-Battery_price[NStages-1]*(soh_initial[NStages]-soh_final[NStages-1])
        gain_stage[NStages]= sum(Power_prices[iStep]*NHoursStep*(discharge[iStep]-charge[iStep]) for iStep=((NStages-1)*NHoursStage+1):(NHoursStage*NStages))
        cost_rev[NStages] = -Battery_price[NStages+1]*(soh_final[NStages]-min_SOH) + Battery_price[NStages]*(soh_initial[NStages]-soh_final[NStages-1])
        

    end
    
    println("Collected results")

    return Results(
        objective,
        revenues_per_stage,
        gain_stage,
        cost_rev,
        deg_stage,
        soc,
        charge,
        discharge,
        aux,
        deg_neg,
        deg_pos,
        soh_final,
        soh_initial,  
    )

end