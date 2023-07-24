# STAGE MAXIMIZATION PROBLEM FORMULATION

function BuildStageProblem(InputParameters::InputParam, SolverParameters::SolverParam, Battery::BatteryParam)       #, state_variables::states When we have 2 hydropower plants- 2 turbines
  
    @unpack (NYears, NMonths, NStages, Big, NSteps, NHoursStep, NHoursStage) = InputParameters;  #, NSteps
    @unpack (energy_Capacity, Eff_charge, Eff_discharge, max_SOH, min_SOH, Nfull, max_disc ) = Battery ;         #MAXCharge, MAXDischarge,

    M = Model(Gurobi.Optimizer)
    
    set_optimizer_attribute(M, "NonConvex", 2)
    #set_optimizer_attribute(M,"MIPFocus",3)
    #set_optimizer_attribute(M, "Heuristics")

    # DEFINE VARIABLES

    @variable(M, 0 <= soc[iStep=1:NSteps+1] <= energy_Capacity, base_name = "Energy")                # MWh   energy_Capacity NSteps
    
    @variable(M, 0 <= charge[iStep=1:NSteps] <= max_disc, base_name=" Charge")
    @variable(M, 0 <= discharge[iStep=1:NSteps] <= max_disc, base_name=" Discharge")
    
    @variable(M, 0 <= auxiliary[iStep=1:NSteps] <= 2, base_name = "Auxiliary ")
    
    @variable(M, 0 <= deg1[iStep=1:NSteps] <= 2*energy_Capacity , base_name = "Degradation discharge")
    @variable(M, 0 <= deg2[iStep=1:NSteps] <= 2*energy_Capacity , base_name = "Degradation charge")

    @variable(M, min_SOH <= soh_final[iStage=1:NStages] <= max_SOH, base_name = "Final_Capacity")        #energy_Capacity
    @variable(M, min_SOH <= soh_new[iStage=1:NStages] <= max_SOH, base_name = "Initial_Capacity")     #energy_Capacity

    # DEFINE OJECTIVE function - length(Battery_price) = NStages+1=21

    @objective(
      M,
      MathOptInterface.MAX_SENSE, 
      sum(Power_prices[iStep]*NHoursStep*(discharge[iStep]-charge[iStep]) for iStep=1:NSteps) -
      sum(Battery_price[iStage]*(soh_new[iStage]-soh_final[iStage-1]) for iStage=2:NStages) - 
      Battery_price[1]*(soh_new[1]-min_SOH) + 
      Battery_price[NStages+1]*(soh_final[NStages]-min_SOH) 
      )
         
    # DEFINE CONSTRAINTS

    @constraint(M,energy[iStep=1:NSteps], soc[iStep] + (charge[iStep]*Eff_charge-discharge[iStep]/Eff_discharge)*NHoursStep == soc[iStep+1] )

    @constraint(M, aux[iStep=1:NSteps], auxiliary[iStep] == (2-(soc[iStep+1]+soc[iStep])/energy_Capacity))

    @constraint(M, deg_neg[iStep=1:NSteps], deg1[iStep] >= discharge[iStep]/Eff_discharge*auxiliary[iStep])
    @constraint(M, deg_pos[iStep=1:NSteps], deg2[iStep] >= charge[iStep]*Eff_discharge*auxiliary[iStep])

    @constraint(M,soh[iStage=1:(NStages-1)], soh_new[iStage+1] >= soh_final[iStage])

    @constraint(M,final_soh[iStage=1:NStages], soh_final[iStage] == soh_new[iStage]- sum(deg1[iStep]+deg2[iStep] for iStep=((iStage-1)*NHoursStage+1):(NHoursStage*iStage))*NHoursStep/(2*Nfull*energy_Capacity) )     #deg2
  
    return BuildStageProblem(
        M,
        soc,
        charge,
        discharge,
        auxiliary,
        deg1,
        deg2,
        soh_final,
        soh_new,
      )
end
