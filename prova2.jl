
@unpack (NYears, NMonths, NStages, NSteps, Big, NHoursStep, NHoursStage) = InputParameters;
@unpack (charge_bat, disc_bat, soc_bat, cum_energy,eq_cyc, soh_f, soh_in) = ResultsOpt;
@unpack (energy_Capacity, Eff_charge, Eff_discharge, max_SOH ) = Battery ; 

cum= sum((charge_bat[iStep])*Eff_charge*NHoursStep+disc_bat[iStep]/Eff_discharge*NHoursStep for iStep=1:NHoursStage)

soc_prova =zeros(20);
soc_prova[1]= soc_bat[1]

for iStep=2:length(soc_prova)
    soc_prova[iStep]= soc_prova[iStep-1]+charge_bat[iStep]*Eff_charge*NHoursStep-disc_bat[iStep]/Eff_discharge*NHoursStep
end