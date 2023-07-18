# STAGE MAXIMIZATION PROBLEM FORMULATION

function BuildStageProblem(InputParameters::InputParam, SolverParameters::SolverParam, Battery::BatteryParam)       #, state_variables::states When we have 2 hydropower plants- 2 turbines

  #4380
    @unpack (
      CPX_PARAM_SCRIND,
      CPX_PARAM_PREIND,
      CPXPARAM_MIP_Tolerances_MIPGap,
      CPX_PARAM_TILIM,
      CPX_PARAM_THREADS,
    ) = SolverParameters
  
   # NSteps=200
    @unpack (NYears, NMonths, NStages, Big, NSteps, NHoursStep, NHoursStage) = InputParameters;  #, NSteps
    @unpack (energy_Capacity, Eff_charge, Eff_discharge, max_SOH, min_SOH ) = Battery ;         #MAXCharge, MAXDischarge,
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


    @variable(M, 0 <= soc[iStep=1:NSteps] <= energy_Capacity, base_name = "Energy")                # MWh   energy_Capacity NSteps
    @variable(M, 0 <= charge[iStep=1:NSteps] <= energy_Capacity, base_name = "Charge")        # <= energy_Capacity*C-rate               # MAXCharge <=energy_Capacity/Eff_charge    - variabile decisionale : ricarico la batteria MW
    @variable(M, 0 <= discharge[iStep=1:NSteps] <= energy_Capacity, base_name = "Discharge")                 # MAXDischarge <=energy_Capacity*Eff_discharge - variabile decisionale: scarico la batteria
    
    @variable(M, 0 <= A[iStage=1:NStages] <= Big, base_name = "Cumulative_energy")
    @variable(M, 0 <= Ncycle[iStage=1:NStages] <= Big, base_name = " Equivalent cycles")
    #@variable(M, 0 <= deg[iStage=1:NStages] <= Big, base_name = "Degradation")

    @variable(M, min_SOH <= soh_final[iStage=1:NStages] <= max_SOH, base_name = "Final_Capacity")        #energy_Capacity
    @variable(M, min_SOH <= soh_new[iStage=1:NStages] <= max_SOH, base_name = "Initial_Capacity")     #energy_Capacity

    # UPDATE OJECTIVE function

    @objective(
      M,
      MathOptInterface.MAX_SENSE,
      sum(Power_prices[iStep]*NHoursStep*(discharge[iStep]-charge[iStep]) for iStep=1:NSteps) -
      sum(Battery_price[iStage]*(soh_new[iStage]-soh_final[iStage-1]) for iStage=2:NStages) - 
      Battery_price[1]*(soh_new[1]-energy_Capacity)
      +Battery_price[2]*(soh_final[1]-energy_Capacity)   #Battery_price[end]*(soh_final[1]-energy_Capacity)
    )
         
    # UPDATE CONSTRAINTS

    @constraint(M,energy[iStep=2:NSteps], soc[iStep-1] + (charge[iStep]*Eff_charge-discharge[iStep]/Eff_discharge)*NHoursStep == soc[iStep] )
    
    @constraint(M,cumulative[iStage=1:NStages], A[iStage] == sum((charge[iStep]*Eff_charge+discharge[iStep]/Eff_discharge)*NHoursStep for iStep=((iStage-1)*NHoursStage+1):(NHoursStage*iStage)) )
  
    @constraint(M,equivalent_cycles[iStage=1:NStages], Ncycle[iStage] == 0.5/(energy_Capacity)*A[iStage])  #((energy_Capacity+max_SOH)/2) 

    #@constraint(M,aux_z[iStep=1:NSteps], z[iStep] == 1)

    #@constraint(M,charge_constraint[iStep=1:NSteps], ch_quad[iStep]*z[iStep]>= charge[iStep]'*charge[iStep]*Eff_charge^2) #*charge[iStep]

    #@constraint(M,discharge_constraint[iStep=1:NSteps], dis_quad[iStep]*z[iStep]>= discharge[iStep]'*discharge[iStep]/Eff_discharge^2) #*discharge[iStep]

    #@constraint(M,soh[iStage=1:(NStages-1)], soh_new[iStage+1] >= soh_final[iStage])

    @constraint(M,final_soh[iStage=1:NStages], soh_final[iStage] == soh_new[iStage]- Ncycle[iStage]*0.000149) # -Ncycle[iStage]*0.000149

    optimize!(M)
      
      @show value.(soc)
      @show value.(charge)
      @show value.(discharge)
      @show objective_value(M)
      #@show value.(z)
      @show value.(Ncycle)
      #@show value.(deg)
      @show value.(soh_new)
      @show value.(soh_final)
  
    return BuildStageProblem(
        M,
        soc,
        charge,
        discharge,
        #ch_quad,
        #dis_quad,
        #z,
        A,
        Ncycle,
        soh_final,
        soh_new,
        #deg,    
      )
end
