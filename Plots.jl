# PLOTS

using Plots

@unpack (NYears, NMonths, NStages, NSteps, Big, NHoursStep, NHoursStage) = InputParameters;
@unpack (charge_bat, disc_bat, soc_bat, cum_energy,eq_cyc, soh_f, soh_in) = ResultsOpt;


# PLOTTING FIRST SEMESTER
x=range(1, NHoursStage, length=NHoursStage)
t1 = plot(x,soc_bat[1:NHoursStage],label = "SOC", lc=:black,size =(1000,600))
plot!(twinx(), disc_bat[1:NHoursStage], seriestype=:scatter, label = "Discharge", lc=:red)
plot!(x,charge_bat[1:NHoursStage], seriestype=:scatter, label = "Charge", lc=:green)

t2 = (x,disc_bat[1:NHoursStage],label = "Disharge", lc=:red,size =(1000,600))
t3= (x,charge_bat[1:NHoursStage],label = "Charge", lc=:blue,size =(1000,600))


y=range(NHoursStage+1,NHoursStage*2, length=NHoursStage)
a1 = plot(y,soc_bat[NHoursStage+1:NHoursStage*2],label = "SOC", lc=:blue,size =(2000,1200))
a2 = plot(y,charge_bat[NHoursStage+1:NHoursStage*2],label = "Charge", lc=:red,size =(2000,1200))
a3 = plot(y,disc_bat[NHoursStage+1:NHoursStage*2],label = "Disharge", lc=:blue,size =(2000,1200))



a=range(NHoursStage*5+1,NHoursStage*6, length=NHoursStage)
b1 = plot(a,soc_bat[NHoursStage*5+1:NHoursStage*6],label = "SOC", lc=:blue,size =(800,400))
b2 = plot(a,charge_bat[NHoursStage*5+1:NHoursStage*6],label = "Charge", lc=:red,size =(800,400))
b3 = plot(a,disc_bat[NHoursStage*5+1:NHoursStage*6],label = "Disharge", lc=:blue,size =(800,400))


# PLOTS FOR REVAMPING
z = range(1,NStages, length=NStages)
z2= range(2,NStages+1,length=NStages)

b1= scatter(z,soh_in[1:NStages], label="Soh_in", mc=:green, size=(800,400),lenegd=:outerbottom)
scatter!(z2,soh_f[1:NStages], label ="Sof_final", mc=:red, size=(800,400), legend=:outerbottom)
plot!(twinx(),Battery_price[1:NStages], label = "Prices batteries",size=(800,400), seriestype=:line, mc=:pink, legend=:bottomleft)