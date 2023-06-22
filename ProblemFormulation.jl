# STAGE MAXIMIZATION PROBLEM FORMULATION

function BuildStageProblem(InputParameters::InputParam, SolverParameters::SolverParam, Battery::BatteryParam)       #, state_variables::states When we have 2 hydropower plants- 2 turbines

    @unpack (
      CPX_PARAM_SCRIND,
      CPX_PARAM_PREIND,
      CPXPARAM_MIP_Tolerances_MIPGap,
      CPX_PARAM_TILIM,
      CPX_PARAM_THREADS,
    ) = SolverParameters
  
    @unpack (NYears, NMonths, NStages, NSteps, Big, NHoursStep, NHoursStage) = InputParameters;
    @unpack (energy_Capacity, Eff_charge, Eff_discharge, max_SOH ) = Battery ;         #MAXCharge, MAXDischarge,
    #@unpack (maxEnergy) = state_variables

    M = Model(
      with_optimizer(
        CPLEX.Optimizer,
        CPX_PARAM_SCRIND = CPX_PARAM_SCRIND,
        CPX_PARAM_PREIND = CPX_PARAM_PREIND,
        CPXPARAM_MIP_Tolerances_MIPGap = CPXPARAM_MIP_Tolerances_MIPGap,
        CPX_PARAM_TILIM = CPX_PARAM_TILIM,
        CPX_PARAM_THREADS = CPX_PARAM_THREADS,
      ),
    )


    @variable(M, 0 <= soc[iStep=1:NSteps] <= energy_Capacity, base_name = "Energy")                # MWh   energy_Capacity
    @variable(M, 0 <= charge[iStep=1:NSteps] <= energy_Capacity, base_name = "Charge")        # <= energy_Capacity*C-rate               # MAXCharge <=energy_Capacity/Eff_charge    - variabile decisionale : ricarico la batteria MW
    @variable(M, 0 <= discharge[iStep=1:NSteps] <= energy_Capacity, base_name = "Discharge")                 # MAXDischarge <=energy_Capacity*Eff_discharge - variabile decisionale: scarico la batteria
    
    @variable(M, 0 <= A[iStage=1:NStages] <= Big, base_name = "Cumulative_energy")
    @variable(M, 0 <= Ncycle[iStage=1:NStages] <= Big, base_name = " Equivalent cycles")
    #@variable(M, 0 <= deg[iStage=1:NStages] <= Big, base_name = "Degradation")

    @variable(M, energy_Capacity <= soh_final[iStage=1:NStages] <= max_SOH, base_name = "Final_Capacity")
    @variable(M, energy_Capacity <= soh_new[iStage=1:NStages] <= max_SOH, base_name = "Initial_Capacity")

    # UPDATE OJECTIVE function

    @objective(
      M,
      MathOptInterface.MAX_SENSE, 
      sum(Power_prices[iStep]*NHoursStep*(discharge[iStep]-charge[iStep]) for iStep=1:NSteps) -
      sum(Battery_price[iStage]*(soh_new[iStage]-soh_final[iStage-1]) for iStage=2:NStages) - 
      Battery_price[1]*(soh_new[1]-energy_Capacity) + Battery_price[end]*(soh_final[end]-energy_Capacity)
      )
         
    # UPDATE CONSTRAINTS

    @constraint(M,energy[iStep=2:NSteps], soc[iStep-1] + (charge[iStep]*Eff_charge-discharge[iStep]/Eff_discharge)*NHoursStep == soc[iStep] )
    
    @constraint(M,cumulative[iStage=1:NStages], A[iStage] == sum((charge[iStep]*Eff_charge+discharge[iStep]/Eff_discharge)*NHoursStep for iStep=((iStage-1)*NHoursStage+1):(NHoursStage*iStage)) )
 
    #@constraint(M,dis[iStage=1:NStages], (discharge[iStep] for iStep=((iStage-1)*NHoursStage+1):(NHoursStage*iStage)) <= soh_new[iStage]*Eff_discharge )
    
    @constraint(M,equivalent_cycles[iStage=1:NStages], Ncycle[iStage] == A[iStage]/energy_Capacity*0.5)  #(energy_Capacity+SOH_max)/2

   # @constraint(M,degradation[iStage=1:NStages], deg[iStage] == Ncycle[iStage]*0.000149)

    @constraint(M,soh[iStage=1:(NStages-1)], soh_new[iStage+1] >= soh_final[iStage])

    @constraint(M,final_soh[iStage=1:NStages], soh_final[iStage] == soh_new[iStage]- Ncycle[iStage]*0.000149) # -Ncycle[iStage]*0.000149
    

    optimize!(M)
      
      @show value.(soc)
      @show value.(charge)
      @show value.(discharge)
      @show objective_value(M)
      @show value.(A)
      @show value.(Ncycle)
      #@show value.(deg)
      @show value.(soh_new)
      @show value.(soh_final)
  
    return BuildStageProblem(
        M,
        soc,
        charge,
        discharge,
        A,
        Ncycle,
        soh_final,
        soh_new,
        #deg,    
      )
end
