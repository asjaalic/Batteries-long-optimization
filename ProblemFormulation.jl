# STAGE MAXIMIZATION PROBLEM FORMULATION

function BuildStageProblem(InputParameters::InputParam, SolverParameters::SolverParam, Battery::BatteryParam)       #, state_variables::states When we have 2 hydropower plants- 2 turbines

    @unpack (
      CPX_PARAM_SCRIND,
      CPX_PARAM_PREIND,
      CPXPARAM_MIP_Tolerances_MIPGap,
      CPX_PARAM_TILIM,
      CPX_PARAM_THREADS,
    ) = SolverParameters
  
    @unpack (NYears, NMonths, NStages, NSteps, Big, NHoursStep) = InputParameters
    @unpack (max_Charge, max_Discharge, energy_Capacity, Eff_charge, Eff_discharge, max_SOH ) = Battery          #MAXCharge, MAXDischarge,
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


    @variable(M, 0 <= soc[iStep=1:NSteps] <= energy_Capacity, base_name = "Energy")                # MWh   power_capacity
    @variable(M, 0 <= charge[iStep=1:NSteps] <= max_Charge, base_name = "Charge")                       # MAXCharge  - variabile decisionale : ricarico la batteria MW
    @variable(M, 0 <= discharge[iStep=1:NSteps] <= max_Discharge, base_name = "Discharge")                 # MAXDischarge - variabile decisionale: scarico la batteria
    
    @variable(M,0<=A[iStage=1:NStages] <= Big, base_name = "Cumulative_energy")
    @variable(M,0<=Ncycle[iStage=1:NStages] <= Big, base_name = " Equivalent cycles")
    @variable(M, 0<= deg[iStage=1:NStages] <= Big, base_name = "Degradation")

    @variable(M, energy_Capacity <= soh_final[iStage=1:NStages] <= max_SOH, base_name = "Final_Capacity")
    @variable(M, energy_Capacity <= soh_new[iStage=1:NStages] <= max_SOH, base_name = "Initial_Capacity")

    # UPDATE OJECTIVE function

    @objective(
      M,
      MathOptInterface.MAX_SENSE, 
      sum(Power_prices[iStep]*NHoursStep*(discharge[iStep]-charge[iStep]) for iStep=1:NSteps) -
      sum(Battery_price[iStage]*(soh_new[iStage]-soh_final[iStage-1]) for iStage=2:NStages) - 
      Battery_price[1]*soh_new[1] + Battery_price[end]*soh_final[end] 
      )
         
    # UPDATE CONSTRAINTS

    @constraint(M,energy[iStep=1:(NSteps-1)], soc[iStep] + (charge[iStep]*Eff_charge-discharge[iStep]/Eff_discharge)*NHoursStep == soc[iStep+1] )
    
    @constraint(M,cumulative[iStage=1:NStages], A[iStage] == sum((charge[iStep]*Eff_charge+discharge[iStep]/Eff_discharge)*NHoursStep for iStep=((iStage-1)*730+1):(730*iStage)) )

    @constraint(M,equivalent_cycles[iStage=1:NStages], Ncycle[iStage] == A[iStage]/energy_Capacity*0.5)

    @constraint(M,degradation[iStage=1:NStages], deg[iStage] == 2.5*Ncycle[iStage]-0.2)

    @constraint(M,soh[iStage=1:NStages-1], soh_new[iStage+1]>= soh_final[iStage])

    @constraint(M,final_soh[iStage=1:NStages], soh_final[iStage]== soh_new[iStage]-deg[iStage])
 
  
    return BuildStageProblem(
        M,
        soc,
        charge,
        discharge,
        A,
        Ncycle,
        soh_final,
        soh_new,
        deg,    
      )
end
