# STAGE MAXIMIZATION PROBLEM FORMULATION

function BuildStageProblem(InputParameters::InputParam, SolverParameters::SolverParam, Battery::BatteryParam)       #, state_variables::states When we have 2 hydropower plants- 2 turbines

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
      )
    )

    #M = Model(Gurobi.Optimizer)
    #set_optimizer_attribute(M, "NonConvex", 2)
    #set_optimizer_attribute(M,"Cuts",1)

    # DEFINE VARIABLES

    @variable(M, 0 <= soc[iStep=1:NSteps+1] <= energy_Capacity, base_name = "Energy")                # MWh   energy_Capacity NSteps
    
    @variable(M, 0 <= charge[iStep=1:NSteps] <= max_disc, base_name=" Int charge")
    @variable(M, 0 <= discharge[iStep=1:NSteps] <= max_disc, base_name=" Int discharge")
    
    @variable(M, 0 <= auxiliary[iStep=1:NSteps] <= 2, base_name = "Auxiliary")
    
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

    #CONSTRAINT FOR CHARGING - DEGRADATION
    @constraint(M, deg_pos_1[iStep=1:NSteps], deg2[iStep] >= Eff_charge*0*2+0*Eff_charge*(auxiliary[iStep]-2)+2*Eff_charge*(charge[iStep]-0))
    @constraint(M, deg_pos_2[iStep=1:NSteps], deg2[iStep] >= Eff_charge*0*1.5+0*Eff_charge*(auxiliary[iStep]-1.5)+1.5*Eff_charge*(charge[iStep]-0))
    @constraint(M, deg_pos_3[iStep=1:NSteps], deg2[iStep] >= Eff_charge*0*1+0*Eff_charge*(auxiliary[iStep]-1)+1*Eff_charge*(charge[iStep]-0))
    @constraint(M, deg_pos_4[iStep=1:NSteps], deg2[iStep] >= Eff_charge*0*0.5+0*Eff_charge*(auxiliary[iStep]-0.5)+0.5*Eff_charge*(charge[iStep]-0))

    @constraint(M, deg_pos_5[iStep=1:NSteps], deg2[iStep] >= Eff_charge*2*1.82+2*Eff_charge*(auxiliary[iStep]-1.82)+1.82*Eff_charge*(charge[iStep]-2))
    @constraint(M, deg_pos_6[iStep=1:NSteps], deg2[iStep] >= Eff_charge*2*1.32+2*Eff_charge*(auxiliary[iStep]-1.32)+1.32*Eff_charge*(charge[iStep]-2))
    @constraint(M, deg_pos_7[iStep=1:NSteps], deg2[iStep] >= Eff_charge*2*0.82+2*Eff_charge*(auxiliary[iStep]-0.82)+0.82*Eff_charge*(charge[iStep]-2))
    @constraint(M, deg_pos_8[iStep=1:NSteps], deg2[iStep] >= Eff_charge*2*0.32+2*Eff_charge*(auxiliary[iStep]-0.32)+0.32*Eff_charge*(charge[iStep]-2))

    @constraint(M, deg_pos_9[iStep=1:NSteps], deg2[iStep] >= Eff_charge*4*1.64+4*Eff_charge*(auxiliary[iStep]-1.64)+1.64*Eff_charge*(charge[iStep]-4))
    @constraint(M, deg_pos_10[iStep=1:NSteps], deg2[iStep] >= Eff_charge*4*1.14+4*Eff_charge*(auxiliary[iStep]-1.14)+1.14*Eff_charge*(charge[iStep]-4))
    @constraint(M, deg_pos_11[iStep=1:NSteps], deg2[iStep] >= Eff_charge*4*0.64+4*Eff_charge*(auxiliary[iStep]-0.64)+0.64*Eff_charge*(charge[iStep]-4))

    @constraint(M, deg_pos_12[iStep=1:NSteps], deg2[iStep] >= Eff_charge*6*1.46+6*Eff_charge*(auxiliary[iStep]-1.46)+1.46*Eff_charge*(charge[iStep]-6))
    @constraint(M, deg_pos_13[iStep=1:NSteps], deg2[iStep] >= Eff_charge*6*0.96+6*Eff_charge*(auxiliary[iStep]-0.96)+0.96*Eff_charge*(charge[iStep]-6))

    @constraint(M, deg_pos_14[iStep=1:NSteps], deg2[iStep] >= Eff_charge*8*1.28+8*Eff_charge*(auxiliary[iStep]-1.28)+1.28*Eff_charge*(charge[iStep]-8))
    @constraint(M, deg_pos_15[iStep=1:NSteps], deg2[iStep] >= Eff_charge*8*0.78+8*Eff_charge*(auxiliary[iStep]-0.78)+0.78*Eff_charge*(charge[iStep]-8))

    @constraint(M, deg_pos_16[iStep=1:NSteps], deg2[iStep] >= Eff_charge*10*1.1+10*Eff_charge*(auxiliary[iStep]-1.1)+1.1*Eff_charge*(charge[iStep]-10))
    

    #CONSTRAINTS FOR DISCHARGING - DEGRADATION
    @constraint(M, deg_neg_1[iStep=1:NSteps], deg1[iStep] >= (0*2+0*(auxiliary[iStep]-2)+2*(discharge[iStep]-0))/Eff_discharge)
    @constraint(M, deg_neg_2[iStep=1:NSteps], deg1[iStep] >= (0*1.5+0*(auxiliary[iStep]-1.5)+1.5*(discharge[iStep]-0))/Eff_discharge)
    @constraint(M, deg_neg_3[iStep=1:NSteps], deg1[iStep] >= (0*1+0*(auxiliary[iStep]-1)+1*(discharge[iStep]-0))/Eff_discharge)
    @constraint(M, deg_neg_4[iStep=1:NSteps], deg1[iStep] >= (0*0.5+0*(auxiliary[iStep]-0.5)+0.5*(discharge[iStep]-0))/Eff_discharge)

    @constraint(M, deg_neg_5[iStep=1:NSteps], deg1[iStep] >= (2*1.72+2*(auxiliary[iStep]-1.72)+1.72*(discharge[iStep]-2))/Eff_discharge)
    @constraint(M, deg_neg_6[iStep=1:NSteps], deg1[iStep] >= (2*1.22+2*(auxiliary[iStep]-1.22)+1.22*(discharge[iStep]-2))/Eff_discharge)
    @constraint(M, deg_neg_7[iStep=1:NSteps], deg1[iStep] >= (2*0.72+2*(auxiliary[iStep]-0.72)+0.72*(discharge[iStep]-2))/Eff_discharge)
    @constraint(M, deg_neg_8[iStep=1:NSteps], deg1[iStep] >= (2*0.22+2*(auxiliary[iStep]-0.22)+0.22*(discharge[iStep]-2))/Eff_discharge)

    @constraint(M, deg_neg_9[iStep=1:NSteps], deg1[iStep] >= (4*1.44+4*(auxiliary[iStep]-1.44)+1.44*(discharge[iStep]-4))/Eff_discharge)
    @constraint(M, deg_neg_10[iStep=1:NSteps], deg1[iStep] >= (4*0.94+4*(auxiliary[iStep]-0.94)+0.94*(discharge[iStep]-4))/Eff_discharge)
    @constraint(M, deg_neg_11[iStep=1:NSteps], deg1[iStep] >= (4*0.44+4*(auxiliary[iStep]-0.44)+0.44*(discharge[iStep]-4))/Eff_discharge)

    @constraint(M, deg_neg_12[iStep=1:NSteps], deg1[iStep] >= (6*1.17+6*(auxiliary[iStep]-1.17)+1.17*(discharge[iStep]-6))/Eff_discharge)
    @constraint(M, deg_neg_13[iStep=1:NSteps], deg1[iStep] >= (6*0.67+6*(auxiliary[iStep]-0.67)+0.67*(discharge[iStep]-6))/Eff_discharge)

    @constraint(M, deg_neg_14[iStep=1:NSteps], deg1[iStep] >= (8*0.89+8*(auxiliary[iStep]-0.89)+0.89*(discharge[iStep]-8))/Eff_discharge)

    #CONSTRAINT ON REVAMPING
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
