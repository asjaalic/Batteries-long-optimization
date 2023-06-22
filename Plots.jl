# PLOTS

using Plots

@unpack (NYears, NMonths, NStages, NSteps, Big, NHoursStep, NHoursStage) = InputParameters;
@unpack (charge_bat, disc_bat, soc_bat, cum_energy,eq_cyc, soh_f, soh_in,rev_stage, degradation) = ResultsOpt;


# PLOTTING FIRST SEMESTER
x=range(1, NHoursStage, length=NHoursStage)
t1 = plot(x,soc_bat[1:NHoursStage],label = "SOC", lc=:black,size =(1000,600))
plot!(twinx(), disc_bat[1:NHoursStage], seriestype=:scatter, label = "Discharge", lc=:red)
plot!(x,charge_bat[1:NHoursStage], seriestype=:scatter, label = "Charge", lc=:green)

x1=range(1,200, length=200)
t2 = plot(x1,disc_bat[1:200],label = "Disharge", lc=:red,size =(1000,600))
plot!(charge_bat[1:200],label = "Charge", lc=:blue,size =(1000,600))
plot!(twinx(),Power_prices[1:200], label ="Power Price", lc=:black, legend=:bottomright)


#PLOTTING THIRD SEMESTER CONSTANT PRICES
y=range(NHoursStage*2+1,NHoursStage*3, length=NHoursStage)
a1 = plot(y,soc_bat[NHoursStage*2+1:NHoursStage*3],label = "SOC", lc=:blue,size =(2000,1200))
a2 = plot(y,charge_bat[NHoursStage*2+1:NHoursStage*3],label = "Charge", lc=:red,size =(2000,1200))
a3 = plot(y,disc_bat[NHoursStage*2+1:NHoursStage*3],label = "Disharge", lc=:blue,size =(2000,1200))



a=range(NHoursStage*18+1,NHoursStage*19, length=NHoursStage)
b1 = plot(a,soc_bat[NHoursStage*18+1:NHoursStage*19],label = "SOC", lc=:blue,size =(800,400))
b2 = plot(a,charge_bat[NHoursStage*18+1:NHoursStage*19],label = "Charge", lc=:red,size =(800,400))
b3 = plot(a,disc_bat[NHoursStage*18+1:NHoursStage*19],label = "Disharge", lc=:blue,size =(800,400))


# PLOTS FOR REVAMPING
z = range(1,NStages, length=NStages)
z2= range(2,NStages+1,length=NStages)
z3= range(1,NStages+1,length=NStages+1)

b1= scatter(z,soh_in[1:NStages], label="Soh_in", mc=:green, size=(800,400),lengend=:outerbottom)
scatter!(z2,soh_f[1:NStages], label ="Sof_final", mc=:red, size=(800,400), legend=:outerbottom)
#plot!(twinx(),z2,cum_energy[1:NStages], lc=:black, marker=:circle, markersize=3, legend=:outerbottom)
plot!(twinx(),Battery_price[1:NStages+1], label = "Prices batteries",size=(800,400), seriestype=:line, mc=:pink, legend=:bottomleft)


b2= plot(z,rev_stage[1:NStages], label = "Revenues", size=(800,400), lc=:blue, legend =:bottomright)
plot!(twinx(),z3,Battery_price[1:NStages+1], label = "Battery prices", lc=:red)

b3=scatter(z,cum_energy[1:NStages], label="Cumulated energy", mc=:blue, size=(800,400),legend=:outerbottom)
scatter!(twinx(),degradation[1:NStages], label ="Degradation",mc=:red)