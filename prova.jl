

 @unpack (NStates,NSteps,NHoursStep, NStages) = InputParameters
 @unpack (charge,discharge,soc,gain,cost_charge,gain_discharge, optimalValueStates, optimalfromState) = ResultsDP;

  optimalStart = findmax(optimalValueStates[1,:])[2]            # Indica lo stato da cui partire all'inizio del giorno 1

  final_soc = zeros(NStages,NSteps)
  final_charges = zeros(NStages,NSteps)
  final_discharges = zeros(NStages,NSteps)
  final_gain = zeros(NStages)
  final_cost_charge = zeros(NStages,NSteps)
  final_gain_discharge = zeros(NStages,NSteps)
  final_values = zeros(NStages)

  # RACCOGLIE I VALORI DELL'OPTIMAL PATH

start = optimalStart

for t=1:NStages                                                       # dall'ultimo giorno t, iState(k=1) e jState(k=49)
      
      finish = Int(optimalfromState[t,start])

      final_soc[t,:]=soc[t,start,finish,:]
      final_charges[t,:]=charge[t,start,finish,:]
      final_discharges[t,:]=discharge[t,start,finish,:]
      final_cost_charge[t,:]=cost_charge[t,start,finish,:]
      final_gain_discharge[t,:]=gain_discharge[t,start,finish,:]
      final_gain[t]=gain[t,start,finish] 
      final_values[t] =optimalValueStates[t,start]

      start=finish

end