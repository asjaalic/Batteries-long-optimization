# STAGE MAXIMIZATION PROBLEM FORMULATION

function BuildStageProblem(InputParameters::InputParam, SolverParameters::SolverParam, Battery::BatteryParam)       #, state_variables::states When we have 2 hydropower plants- 2 turbines

    @unpack (
      CPX_PARAM_SCRIND,
      CPX_PARAM_PREIND,
      CPXPARAM_MIP_Tolerances_MIPGap,
      CPX_PARAM_TILIM,
      CPX_PARAM_THREADS,
    ) = SolverParameters
  
    @unpack (NSteps, Big, NHoursStep) = InputParameters
    @unpack (max_Charge, max_Discharge, energy_Capacity, Eff_charge, Eff_discharge ) = Battery          #MAXCharge, MAXDischarge,
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
    @variable(M, value_next <= Big, base_name = "Value next stage") 

    # UPDATE OJECTIVE function

    @objective(M,MathOptInterface.MAX_SENSE, sum(Power_prices[iStep]*discharge[iStep]-Power_prices[iStep]*charge[iStep] for iStep=1:NSteps))
         
    # UPDATE CONSTRAINTS

    @constraint(M,energy[iStep=1:(NSteps-1)], soc[iStep] + (Eff_charge*charge[iStep]-discharge[iStep]/Eff_discharge)*NHoursStep == soc[iStep+1] )
    #@constraint(M,State_variable[iStep=1:(NSteps-1)], soc[iStep] + (Eff_charge*charge[iStep]-discharge[iStep]/Eff_discharge)*NHoursStep == soc[iStep+1])

    #@constraint(M,endingE[iStep=1], soc[iStep] == energy_Capacity)
    #@constraint(M,Value_next_stage, value_next == energy_Capacity)  # aggiungere "costo" per caricare la batteria il primo giorno

    #@timeit to "Solving optimization problem" 
    optimize!(M)

    @show termination_status(M)
    @show primal_status(M)
    @show dual_status(M)
    
    @show objective_value(M)
    @show value.(soc)
    @show value.(charge)
    @show value.(discharge)
   
  
    return BuildStageProblem(
        M,
        #value_next,
        soc,
        charge,
        discharge,
        #Final_state_variable,
        #State_variable,
        #Value_next_stage,
        energy,       
      )
end
