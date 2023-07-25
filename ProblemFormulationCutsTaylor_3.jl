# STAGE MAXIMIZATION PROBLEM FORMULATION

function BuildStageProblem(InputParameters::InputParam, SolverParameters::SolverParam, Battery::BatteryParam)       #, state_variables::states When we have 2 hydropower plants- 2 turbines

    @unpack (
      MIPGap,
    ) = SolverParameters;
  
    @unpack (NYears, NMonths, NStages, Big, NSteps, NHoursStep, NHoursStage, conv) = InputParameters;  #, NSteps
    @unpack (energy_Capacity, Eff_charge, Eff_discharge, max_SOH, min_SOH, Nfull, max_disc ) = Battery ;         #MAXCharge, MAXDischarge,

    k= NHoursStep*energy_Capacity/(2*Nfull*energy_Capacity)
    deg_max = (1/Eff_discharge)^0.5        # 1.05
    deg_A = deg_max/3                 
    deg_B = deg_max*2/3
/

    M = Model(Gurobi.Optimizer)
    set_optimizer_attribute(M, "MIPGap", MIPGap)
    #set_optimizer_attribute(M,"Cuts",1)

    # DEFINE VARIABLES

    @variable(M, 0 <= soc[iStep=1:NSteps+1] <= energy_Capacity, base_name = "Energy")                # MWh   energy_Capacity NSteps
    
    @variable(M, 0 <= charge[iStep=1:NSteps] <= 1, base_name= "Charge")      #max_disc   0<=discharge<=1
    @variable(M, 0 <= discharge[iStep=1:NSteps] <= 1, base_name= "Discharge")
    
    @variable(M, 0 <= SOC_aux[iStep=1:NSteps] <= 2, base_name = "Auxiliary for SOC")            #2k
    @variable(M, 0 <= P_aux[iStep=1:NSteps] <= deg_max^2, base_name = "Auxiliary power" )  #1/eff

    @variable(M, min_SOH <= soh_final[iStage=1:NStages] <= max_SOH, base_name = "Final_Capacity")        #energy_Capacity
    @variable(M, min_SOH <= soh_new[iStage=1:NStages] <= max_SOH, base_name = "Initial_Capacity")     #energy_Capacity

    #VARIABLES FOR CUTS AND DEGRADATION

    @variable(M, u1[iStep=1:NSteps], Bin, base_name = "Binary A")
    @variable(M, u2[iStep=1:NSteps], Bin, base_name = "Binary B")

    @variable(M, 0<= d[iStep=1:NSteps] <= deg_max^2, base_name = "Degradation_y")
    @variable(M, 0<= deg[iStep=1:NSteps] <= deg_max, base_name = "Degradation_x")
    
    @variable(M, 0 <= d_1[iStep=1:NSteps] <= deg_A^2, base_name = "d_1")  
    @variable(M, 0 <= deg_1[iStep=1:NSteps] <= deg_A , base_name = "Deg_1")       

    @variable(M, 0 <= d_2[iStep=1:NSteps] <= deg_B^2, base_name = "d_2")  
    @variable(M, 0 <= deg_2[iStep=1:NSteps] <= deg_B , base_name = "Deg_2")   

    @variable(M, 0 <= d_3[iStep=1:NSteps] <= deg_max^2, base_name = "d_2")  
    @variable(M, 0 <= deg_3[iStep=1:NSteps] <= deg_max , base_name = "Deg_2")


    # DEFINE OJECTIVE function - length(Battery_price) = NStages+1=21

    @objective(
      M,
      MathOptInterface.MAX_SENSE, 
      sum(Power_prices[iStep]*NHoursStep*energy_Capacity*(discharge[iStep]-charge[iStep]) for iStep=1:NSteps) -
      sum(Battery_price[iStage]*(soh_new[iStage]-soh_final[iStage-1]) for iStage=2:NStages) - 
      Battery_price[1]*(soh_new[1]-min_SOH) + 
      Battery_price[NStages+1]*(soh_final[NStages]-min_SOH) 
      )
         
    # DEFINE CONSTRAINTS

    @constraint(M,energy[iStep=1:NSteps], soc[iStep] + (charge[iStep]*Eff_charge-discharge[iStep]/Eff_discharge)*energy_Capacity*NHoursStep == soc[iStep+1] )

    @constraint(M, SOCaux[iStep=1:NSteps], SOC_aux[iStep] == (soc[iStep+1]+soc[iStep])/energy_Capacity) 
    
    @constraint(M,Paux[iStep=1:NSteps], P_aux[iStep]==(charge[iStep]*Eff_charge+discharge[iStep]/Eff_discharge))    

    @constraint(M, substitution[iStep=1:NSteps], deg[iStep]*deg[iStep] <= SOC_aux[iStep]*P_aux[iStep] )

    # CONSTRAINTS FOR LINEARIZATION

    @constraint(M, deg_x[iStep=1:NSteps], deg[iStep] == deg_1[iStep]+deg_2[iStep]+deg_3[iStep] )
    @constraint(M, deg_y[iStep=1:NSteps], d[iStep] == d_1[iStep]+d_2[iStep]+d_3[iStep])

    # UPPER Cuts for deg_1 and d_1
    @constraint(M, lower_deg1[iStep=1:NSteps], deg_1[iStep] >= 0*u1[iStep])
    @constraint(M, upper_deg1[iStep=1:NSteps], deg_1[iStep] <= u1[iStep]*deg_A)

    @constraint(M, upper_d1[iStep=1:NSteps], d_1[iStep] <= deg_A*deg_1[iStep])

    # UPPER CUTS FOR deg_2 and d_2
    @constraint(M, lower_deg2[iStep=1:NSteps], deg_2[iStep] >= u2[iStep]*deg_A)
    @constraint(M, upper_deg2[iStep=1:NSteps], deg_2[iStep] <= u2[iStep]*deg_B)

    @constraint(M,upper_d2[iStep=1:NSteps], d_2[iStep] <= deg_2[iStep]*(deg_A+deg_B)-(1-u2[iStep])*(deg_A*deg_B))

    #UPPER CUTS FOR Deg_3 and d_3
    @constraint(M, lower_deg3[iStep=1:NSteps], deg_3[iStep] >= (1-u1[iStep]-u2[iStep])*deg_B)
    @constraint(M, upper_deg3[iStep=1:NSteps], deg_3[iStep] <= (1-u1[iStep]-u2[iStep])*deg_max)

    @constraint(M,upper_d3[iStep=1:NSteps], d_3[iStep] <= deg_3[iStep]*(deg_max+deg_B)-(1-u1[iStep]-u2[iStep])*(deg_max*deg_B))

    #LOWER CUTS
    @constraint(M, deg_pos_1[iStep=1:NSteps], d[iStep]>= 2*0*deg[iStep]-(0)^2)
    @constraint(M, deg_pos_2[iStep=1:NSteps], d[iStep]>= 2*0.12*deg[iStep]-(0.12)^2)
    @constraint(M, deg_pos_3[iStep=1:NSteps], d[iStep]>= 2*0.23*deg[iStep]-(0.23)^2)
    @constraint(M, deg_pos_4[iStep=1:NSteps], d[iStep]>= 2*0.35*deg[iStep]-(0.35)^2)
    @constraint(M, deg_pos_5[iStep=1:NSteps], d[iStep]>= 2*0.47*deg[iStep]-(0.47)^2)    
    @constraint(M, deg_pos_6[iStep=1:NSteps], d[iStep]>= 2*0.59*deg[iStep]-(0.59)^2)
    @constraint(M, deg_pos_7[iStep=1:NSteps], d[iStep]>= 2*0.70*deg[iStep]-(0.70)^2)
    @constraint(M, deg_pos_8[iStep=1:NSteps], d[iStep]>= 2*0.82*deg[iStep]-(0.82)^2)
    @constraint(M, deg_pos_9[iStep=1:NSteps], d[iStep]>= 2*0.94*deg[iStep]-(0.94)^2)
    @constraint(M, deg_pos_10[iStep=1:NSteps], d[iStep]>= 2*1.05*deg[iStep]-(1.05)^2)


    #CONSTRAINT ON REVAMPING

    @constraint(M, deg_tot[iStep=1:NSteps], 2*P_aux[iStep]-d[iStep]>=0 )

    @constraint(M,soh[iStage=1:(NStages-1)], soh_new[iStage+1] >= soh_final[iStage])

    @constraint(M,final_soh[iStage=1:NStages], soh_final[iStage] == soh_new[iStage]- sum(2*P_aux[iStep]-d[iStep] for iStep=((iStage-1)*NHoursStage+1):(NHoursStage*iStage))*k )     #deg2

    return BuildStageProblem(
        M,
        soc,
        charge,
        discharge,
        SOC_aux,
        P_aux,
        d,
        deg,
        u1,
        u2,
        d_1,
        d_2,
        d_3,
        deg_1,
        deg_2,
        deg_3,
        soh_final,
        soh_new,
      )
end



  # LINEAR LINEARIZATION
  #=
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

  =#