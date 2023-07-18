# STAGE MAXIMIZATION PROBLEM FORMULATION

#function BuildStageProblem(InputParameters::InputParam, SolverParameters::SolverParam, Battery::BatteryParam)       #, state_variables::states When we have 2 hydropower plants- 2 turbines

    @unpack (
      CPX_PARAM_SCRIND,
      CPX_PARAM_PREIND,
      CPXPARAM_MIP_Tolerances_MIPGap,
      CPX_PARAM_TILIM,
      CPX_PARAM_THREADS,
    ) = SolverParameters
  
    @unpack (NYears, NMonths, NStages, Big, NSteps, NHoursStep, NHoursStage) = InputParameters;  #, NSteps
    @unpack (energy_Capacity, Eff_charge, Eff_discharge, max_SOH, min_SOH, Nfull, max_disc ) = Battery ;         #MAXCharge, MAXDischarge,

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

    # DEFINE VARIABLES

    @variable(M, 0 <= soc[iStep=1:NSteps+1] <= energy_Capacity, base_name = "Energy")                # MWh   energy_Capacity NSteps
    
    @variable(M, 0 <= n_charge[iStep=1:NSteps] <= max_disc, Int, base_name=" Int_charge")
    @variable(M, 0 <= n_discharge[iStep=1:NSteps] <= max_disc, integer= true, base_name=" Int_discharge")
    
    @variable(M, 0 <= auxiliary[iStep=1:NSteps] <= 2, base_name = "Auxiliary")
    
    @variable(M, 0 <= deg1[iStage=1:NStages] <= Big, base_name = "Degradation discharge")
    @variable(M, 0 <= deg2[iStage=1:NStages] <= Big, base_name = "Degradation charge")

    @variable(M, min_SOH <= soh_final[iStage=1:NStages] <= max_SOH, base_name = "Final_Capacity")        #energy_Capacity
    @variable(M, min_SOH <= soh_new[iStage=1:NStages] <= max_SOH, base_name = "Initial_Capacity")     #energy_Capacity

    # DEFINE OJECTIVE function - length(Battery_price) = NStages+1=21

    @objective(
      M,
      MathOptInterface.MAX_SENSE, 
      sum(Power_prices[iStep]*NHoursStep*energy_Capacity/max_disc*(n_discharge[iStep]-n_charge[iStep]) for iStep=1:NSteps) -
      sum(Battery_price[iStage]*(soh_new[iStage]-soh_final[iStage-1]) for iStage=2:NStages) - 
      Battery_price[1]*(soh_new[1]-min_SOH) + 
      Battery_price[NStages+1]*(soh_final[NStages]-min_SOH) #Battery_price[end]
      )
         
    # DEFINE CONSTRAINTS

    @constraint(M,energy[iStep=1:NSteps], soc[iStep] + (n_charge[iStep]*Eff_charge-n_discharge[iStep]/Eff_discharge)*NHoursStep*energy_Capacity/max_disc == soc[iStep+1] )

    @constraint(M, aux[iStep=1:NSteps], auxiliary[iStep] == (2-(soc[iStep+1]+soc[iStep])/energy_Capacity))

    @constraint(M, deg_discharge[iStage=1:NStages], deg1[iStage] >= (sum(n_discharge[iStep]/Eff_discharge*auxiliary[iStep] for iStep=((iStage-1)*NHoursStage+1):(NHoursStage*iStage))*energy_Capacity/max_disc*NHoursStep)/(2*Nfull*energy_Capacity))
    @constraint(M, deg_charge[iStage=1:NStages], deg2[iStage] >= (sum(n_charge[iStep]*Eff_charge*auxiliary[iStep] for iStep=((iStage-1)*NHoursStage+1):(NHoursStage*iStage))*energy_Capacity/max_disc*NHoursStep)/(2*Nfull*energy_Capacity))
    
    @constraint(M,soh[iStage=1:(NStages-1)], soh_new[iStage+1] >= soh_final[iStage])

    @constraint(M,final_soh[iStage=1:NStages], soh_final[iStage] == soh_new[iStage]- deg1[iStage] -deg2[iStage])     #deg2
  
    optimize!(M)

    return BuildStageProblem(
        M,
        soc,
        #charge,
        #discharge,
        n_charge,
        n_discharge,
        auxiliary,
        #deg,
        deg1,
        deg2,
        soh_final,
        soh_new,
      )
#end
