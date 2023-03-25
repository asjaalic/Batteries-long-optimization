function DP(                                                                                                   # Ora conosco per ogni settimana i valori di inflow e prezzo (calcolati con il modello di Markov) - risolvo il problema come "DETERMINISTICO"
  InputParameters::InputParam,
  SolverParameters::SolverParam,
  Battery::BatteryParam,
  state_variables::states,
  )

  @unpack (NStages, NStates, NSteps, NHoursStage, NHoursStep, Big) = InputParameters
  @unpack (power_Capacity, energy_Capacity, Eff_charge, Eff_discharge) = Battery      # MAXCharge, MAXDischarge,
  @unpack (CPX_PARAM_SCRIND, CPX_PARAM_PREIND, CPXPARAM_MIP_Tolerances_MIPGap, CPX_PARAM_TILIM, CPX_PARAM_THREADS) = SolverParameters
  @unpack (seg, maxEnergy) = state_variables

  println("Evaluating optimal trajectory without battery_replacement: ")

  optimalValueStates = zeros(NStages,NStates)                                # Final Optimal value for each State of the t-stage -> considers the max among all combinations ex: ValueStates[23,5] = 124€ -> if we are in day 23 at stage 5, the value I would have is of 124€
  optimalfromState = zeros(NStages,NStates)                                    # Indicates the optimal state of the next stage from which we are coming from ex: fromState[23,5] =2 -> if we are at day 24 in state 5 (0% of energy), we are comiing from state 2 in day 24

  val = zeros(NStages,NStates,NStates)                                         # Per ogni stato del sistema, calcolo tutte le transizioni e poi ne prendo la massima
                                                                               # ex: Val[35,1,4] = indicates the value of being in state 1 in day 35, id coming from state 4 in stage 36
  power_price = Power_prices
  finalState = 10 #MWh
  #initialState = 10 #MWh

  # VECTORS FOR EVERY POSSIBLE COMBINATION
  charge = zeros(NStages,NStates,NStates,NSteps) 
  discharge = zeros(NStages,NStates,NStates,NSteps)
  soc = zeros(NStages,NStates,NStates,NSteps)
  gain = zeros(NStages,NStates,NStates)
  cost_charge = zeros(NStages,NStates,NStates,NSteps)
  gain_discharge =zeros(NStages,NStates,NStates,NSteps)

  # VECTORS FOR OPTIMAL FINAL VALUES
  final_soc = zeros(NStages,NStates,NSteps)
  final_charges = zeros(NStages,NStates,NSteps)
  final_discharges = zeros(NStages,NStates,NSteps)
  final_gain = zeros(NStages,NStates)
  final_cost_charge = zeros(NStages,NStates,NSteps)
  final_gain_discharge = zeros(NStages,NStates,NSteps)
    
  Problem = BuildStageProblem(InputParameters,SolverParameters,Battery,state_variables)  
    
  nProblems = 0

  for t = NStages:-1:1                                                       # Calcolo per ogni giorno partendo dall'ultimo
    println("t:", t)
    
    for iState=1:NStates                                                     # Considero gg=365 tutti i possibili stati

        for jState=1:NStates                                                 # Considero tutti gli stati allo stagesuccessivo

          #UPDATES THE STEPS FOR EACH POSSIBLE STATE OF THE SYSTEM

          Problem = update_input(
            t,
            iState,
            jState,
            Problem,
            power_price,
            NHoursStep,
            NSteps,
            seg,
            optimalValueStates,
            finalState,
            #initialState,
          )

          @timeit to "Solving optimization problem" optimize!(Problem.model)
            nProblems = nProblems+1
            if termination_status(Problem.model)!= MOI.OPTIMAL
              println("NOT OPTIMAL: ", termination_status(Problem.model))
            end

          @timeit to "Collecting results" begin
            # RACCOLGO I RISULTATI PER OGNI TRANSIZIONE iState --> jState
                  
            val[t,iState,jState]= JuMP.objective_value(Problem.model)

            for iStep=1:NSteps
              charge[t,iState,jState,iStep]= JuMP.value(Problem.charge[iStep])
              discharge[t,iState,jState,iStep]= JuMP.value(Problem.discharge[iStep])
              soc[t,iState,jState,iStep] = JuMP.value(Problem.soc[iStep])
            
              cost_charge[t,iState,jState,iStep] = charge[t,iState,jState,iStep]*power_price[t,iStep]*NHoursStep
              gain_discharge[t,iState,jState,iStep] = discharge[t,iState,jState,iStep]*power_price[t,iStep]*NHoursStep
              
              gain[t,iState,jState] = gain[t,iState,jState]+gain_discharge[t,iState,jState,iStep]-cost_charge[t,iState,jState,iStep]
            
            end

          end   

            # PER OGNI TRANSIZIONE, HO LA SEQUENZA (o profilo) DI CARICHE/SCARICHE
            # posso usare il rainflow counting alg. per calcolare il numero di cicli equivalenti alla fine di ogni giorno

        end # end jStates=1:5

      optimalValueStates[t,iState] = findmax(val[t,iState,:])[1]             # Trovo il massimo del Valore funzione obiettivo : transizioni + valore stato precedente 
      optimalfromState[t,iState] = findmax(val[t,iState,:])[2]               # Mi dice da quale stato al giorno precedente (o futuro) arrivo
   
    end

  end   # end Stages=1:365

  # RACCOGLIE I VALORI OTTIMALI PER OGNI STATO DI OGNI STAGE

  for t=1:NStages
    for iState=1:NStates

      #a=optimalValueStates[t,iState]
      b=Int(optimalfromState[t,iState])

      for iStep=1:NSteps

        final_soc[t,iState,iStep]=soc[t,iState,b,iStep]
        final_charges[t,iState,iStep]=charge[t,iState,b,iStep]
        final_discharges[t,iState,iStep]=discharge[t,iState,b,iStep]
        final_cost_charge[t,iState,iStep]=cost_charge[t,iState,b,iStep]
        final_gain_discharge[t,iState,iStep]=gain_discharge[t,iState,b,iStep]
        
      end

      final_gain[t,iState]=gain[t,iState,b] 

    end
  end

  return Results_dp(
    soc,
    charge,
    discharge,
    gain,
    power_price,
    cost_charge,
    gain_discharge,
    optimalValueStates,
    optimalfromState,
    final_soc,
    final_charges,
    final_discharges,
    final_cost_charge,
    final_gain_discharge,
    final_gain,
    val,
  )
end


# FUNCTION TO UPDATE STEP PARAMETERS BEFORE SOLVING STAGE PROBLEM

function update_input(
  t,
  iState,
  jState,
  Problem,
  power_price,
  NHoursStep,
  NSteps,
  seg,
  optimalValueStates,        # vettore NStages x NSteps
  finalState,
  #initialState,
  )

  # con jState =1: NStates --> 1=100%, 2=75%, 3=50%, 4=25%, 5=0%

    for iStep=NSteps:-1:1                                                 # parto da 8 e vado fino a 1
          
      set_objective_coefficient(
        Problem.model,                                                                                        
        Problem.discharge[iStep],                                                                             
        NHoursStep * power_price[t,iStep],                                                                       
        )
      set_objective_coefficient(
        Problem.model,                                                                                         
        Problem.charge[iStep],                                                                             
        -NHoursStep * power_price[t,iStep],                                                                       
        )  
          
        if t==NStages
          if iStep==NSteps  
            JuMP.set_normalized_rhs(
              Problem.Final_state_variable[iStep],
              finalState                                        #soc[t+1,1]
              )
          end
        else
          if iStep==NSteps  
            JuMP.set_normalized_rhs(
              Problem.Final_state_variable[iStep],
              seg[jState]                                        #soc[t+1,1]
              )
          end
        end

        if t==1
          #=if iStep==1
            JuMP.set_normalized_rhs(
              Problem.endingE[iStep],
              initialState
            )
          end
        else =#
          if iStep==1
            JuMP.set_normalized_rhs(
              Problem.endingE[iStep],
              seg[iState]
            )
          end
        end

    end
                        
    if t==NStages
      JuMP.set_normalized_rhs(Problem.Value_next_stage, finalState*power_price[t,end]) 
    else                  
      JuMP.set_normalized_rhs(Problem.Value_next_stage, optimalValueStates[t+1,jState] )
    end


  return Problem
end