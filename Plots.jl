# PLOTS

using Plots

@unpack (NStages, NStates, NSteps, NHoursStage, NHoursStep, Big) = InputParameters
@unpack (final_soc, final_charges, final_discharges, final_cost_charge, final_gain_discharge, final_gain,final_values, optimalState, optimalfromState) = ResultsDP;
@unpack (seg) = state_variables

# PLOTTING OPTIMAL STATES
x=range(1, NStages+1, length=NStages+1)
t1=plot(x,optimalState,label = "Optimal trajectory", lc=:blue,size =(1000,600),yflip = true)

a=range(1,1,1)
plot(t1,a,optimalState[1:1],seriestype=:scatter)

a=range(2,2,1)
plot!(a,optimalState[2:2],seriestype=:scatter)

a=range(3,3,1)
plot!(a,optimalState[3:3],seriestype=:scatter)

for i=1:(NStages+1)
    println("Day $i")
    a=range(i,i,1)
    println("Range $a")
    plot!(a,optimalState[i:i], seriestype=:scatter)
end

# Plotta valori concatenati - RIVEDI SOC!
concat_soc=zeros(NStages*NSteps+1);
concat_decisions=zeros(NStages*NSteps);

for t=1:NStages
    concat_soc[(NSteps*(t-1))+1:1:(NSteps*t)] = final_soc[t,:]          #final_soc[1:48]
    concat_decisions[(NSteps*(t-1))+1:1:(NSteps*t)] = final_charges[t,:]-final_discharges[t,:]
end

finalValue=Int(optimalState[end])
concat_soc[end]=seg[finalValue]

# QUESTA SOTTO DOVREBBE ESSERE LA VERSIONE GIUSTA SE CONSIDERIAMO ANCHE LO SOC DI ARRIVO


b=range(1,NSteps*NStages+1,length=NSteps*NStages+1)
grafico=plot(b,concat_soc[1:(NSteps*NStages)+1], label ="SOC profile", size=(2000,600), lc=:black, legend =:bottomright)

a=range(49,49,length=1)
plot!(a,concat_soc[49:49],seriestype=:scatter)

a2=range(97,97,length=1)
plot!(a2,concat_soc[97:97],seriestype=:scatter)

a3=range(145,145,length=1)
plot!(a3,concat_soc[145:145],seriestype=:scatter)

a4=range(193,193,length=1)
plot!(a4,concat_soc[193:193],seriestype=:scatter)

a5=range(241,241,length=1)
plot!(a5,concat_soc[241:241],seriestype=:scatter)

a6=range(289,289,length=1)
plot!(a6,concat_soc[289:289],seriestype=:scatter)

a7=range(337,337,length=1)
plot!(a7,concat_soc[337:337],seriestype=:scatter)

a8=range(385,385,length=1)
plot!(a8,concat_soc[385:385],seriestype=:scatter)

a9=range(433,433,length=1)
plot!(a9,concat_soc[433:433],seriestype=:scatter)

a10=range(481,481,length=1)
plot!(a10,concat_soc[481:481],seriestype=:scatter)


a28=range(1345,1345,length=1)
plot!(a28,concat_soc[1345:1345],seriestype=:scatter , legend=false)

a29=range(1393,1393,length=1)
plot!(a29,concat_soc[1393:1393],seriestype=:scatter , legend=false)

a30=range(1441,1441,length=1)
plot!(a30,concat_soc[1441:1441],seriestype=:scatter , legend=false)


# PLOT CHARGE-DISCHARGE PROFILES

x=range(1,NSteps*NStages,length=NSteps*NStages)
grafico2=plot(x,concat_decisions[1:(NSteps*NStages)], label ="Charge-discharge profile", size=(2000,600), lc=:black, legend =:bottomright)

graph3= plot(x, [concat_soc[1:(NSteps*NStages)],concat_decisions[1:(NSteps*NStages)]], layout =(2,1),size=(2000,600))

x=range(1,48,length=48)
grafico2=plot(x,concat_decisions[1:48], label ="Charge-discharge profile", size=(2000,600), lc=:black, legend =:bottomright)

x=range(1,192,length=192)
grafico2=plot(x,concat_decisions[1:192], label ="Charge-discharge profile", size=(2000,600), lc=:black, legend =:bottomright)

x=range(1,192,length=192)
grafico2=plot(x,concat_soc[1:192], label ="Charge-discharge profile", size=(2000,600), lc=:black, legend =:bottomright)