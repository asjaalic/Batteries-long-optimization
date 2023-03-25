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

  optimalValueStates = zeros(NStages+1,NStates)                                # Final Optimal value for each State of the t-stage -> considers the max among all combinations ex: ValueStates[23,5] = 124€ -> if we are in day 23 at stage 5, the value I would have is of 124€
  optimalValueStates[end,:] = seg * Power_prices[end,end]/2
  optimalfromState = zeros(NStages,NStates)                                    # Indicates the optimal state of the next stage from which we are coming from ex: fromState[23,5] =2 -> if we are at day 24 in state 5 (0% of energy), we are comiing from state 2 in day 24

  val = zeros(NStages,NStates,NStates)                                         # Per ogni stato del sistema, calcolo tutte le transizioni e poi ne prendo la massima
  #optimalStart=zeros(Float64,2)                                                                             # ex: Val[35,1,4] = indicates the value of being in state 1 in day 35, id coming from state 4 in stage 36
  power_price = Power_prices

  # VECTORS FOR EVERY POSSIBLE COMBINATION
  charge = zeros(NStages,NStates,NStates,NSteps) 
  discharge = zeros(NStages,NStates,NStates,NSteps)
  soc = zeros(NStages,NStates,NStates,NSteps+1)
  gain = zeros(NStages,NStates,NStates)
  cost_charge = zeros(NStages,NStates,NStates,NSteps)
  gain_discharge =zeros(NStages,NStates,NStates,NSteps)

  # VECTORS FOR OPTIMAL FINAL VALUES
  final_soc = zeros(NStages,NSteps)
  final_charges = zeros(NStages,NSteps)
  final_discharges = zeros(NStages,NSteps)
  final_gain = zeros(NStages)
  final_cost_charge = zeros(NStages,NSteps)
  final_gain_discharge = zeros(NStages,NSteps)
  final_values = zeros(NStages)
  optimalState =zeros(NStages+1)
    
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
          )

          @timeit to "Solving optimization problem" optimize!(Problem.model)
            nProblems = nProblems+1
            if termination_status(Problem.model)!= MOI.OPTIMAL
              println("NOT OPTIMAL: ", termination_status(Problem.model))
            end

          @timeit to "Collecting results" begin
            # RACCOLGO I RISULTATI PER OGNI TRANSIZIONE iState --> jState
                  
            val[t,iState,jState]= JuMP.objective_value(Problem.model)                                           # Value of the objective function

            for iStep=1:NSteps
              charge[t,iState,jState,iStep]= JuMP.value(Problem.charge[iStep])
              discharge[t,iState,jState,iStep]= JuMP.value(Problem.discharge[iStep])
              soc[t,iState,jState,iStep] = JuMP.value(Problem.soc[iStep])
            
              cost_charge[t,iState,jState,iStep] = charge[t,iState,jState,iStep]*power_price[t,iStep]*NHoursStep
              gain_discharge[t,iState,jState,iStep] = discharge[t,iState,jState,iStep]*power_price[t,iStep]*NHoursStep
              
              gain[t,iState,jState] = gain[t,iState,jState]+gain_discharge[t,iState,jState,iStep]-cost_charge[t,iState,jState,iStep]
            
            end

          end   

          soc[t,iState,jState,end] =  seg[jState]  #SERVE PER IL RAINFLOW COUNTING ALGORITHM       

          # PER OGNI TRANSIZIONE, HO LA SEQUENZA (o profilo) DI CARICHE/SCARICHE
          # posso usare il rainflow counting alg. per calcolare il numero di cicli equivalenti alla fine di ogni giorno

        end # end jStates=1:5

      optimalValueStates[t,iState] = findmax(val[t,iState,:])[1]             # Trovo il massimo del Valore funzione obiettivo : transizioni + valore stato precedente 
      optimalfromState[t,iState] = findmax(val[t,iState,:])[2]               # Mi dice da quale stato al giorno precedente (o futuro) arrivo
   
    end

  end   # end Stages=1:365

  # RACCOLGO I RISULTATI DEL PERCORSO MIGLIORE

  start = findmax(optimalValueStates[1,:])[2] 

  for t=1:NStages                                                       # dall'ultimo giorno t, iState(k=1) e jState(k=49)
        
        finish = Int(optimalfromState[t,start])
  
        final_soc[t,:]=soc[t,start,finish,1:48]                            # dovrebbero essee 49 valori di soc effettivi
        final_charges[t,:]=charge[t,start,finish,:]
        final_discharges[t,:]=discharge[t,start,finish,:]
        final_cost_charge[t,:]=cost_charge[t,start,finish,:]
        final_gain_discharge[t,:]=gain_discharge[t,start,finish,:]
        final_gain[t]=gain[t,start,finish] 
        final_values[t] =optimalValueStates[t,start]
        optimalState[t]=start
        start=finish
  end
  
  optimalState[end]=start   
  

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
    final_values,
    optimalState,
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
  )

  # con jState =1: NStates --> 1=100%, 2=88.8%, 3=77.77%, 4=66.66%, 5=55.55%, 6=44.44%, 7=33.33%, 8=22.22%, 9=11.11%, 10=0%

    for iStep=1:NSteps                                                 # iStep=NSteps:-1:1 parto da 8 e vado fino a 1
          
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
                                                      
        if iStep==NSteps  
          JuMP.set_normalized_rhs(
            Problem.Final_state_variable[iStep],
            seg[jState]                                        #soc[t+1,1]
            )
        end

        if iStep==1
          JuMP.set_normalized_rhs(
            Problem.endingE[iStep],
            seg[iState]
          )
        end

    end
         
    if t==1  
      JuMP.set_normalized_rhs(Problem.Value_next_stage, optimalValueStates[t+1,jState]-seg[iState]*23.40)     
    else
      JuMP.set_normalized_rhs(Problem.Value_next_stage, optimalValueStates[t+1,jState]) 
    end
      #JuMP.set_normalized_rhs(Problem.Value_next_stage, soc[t+1,1]*power_price[t,end])


  return Problem
end