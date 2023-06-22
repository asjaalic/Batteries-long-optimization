# EXCEL SAVINGS
#using DataFrames
#using XLSX

#function data_saving(runMode::runModeParam, InputParameters::InputParam,ResultsDP::Results_dp)

    @unpack (NYears, NMonths, NStages, NSteps, Big, NHoursStep, NHoursStage) = InputParameters;
    @unpack (charge_bat,disc_bat, soc_bat,cum_energy,eq_cyc, soh_f, soh_in,rev_stage, degradation, gain, cost_rev) = ResultsOpt;
    
    hour=string(now())
    a=replace(hour,':'=> '-')

    nameF= "$NYears years, $NMonths monthsPerStage, $NStages stages, $NSteps steps, $a"

    folder = "$nameF"
    mkdir(folder)
    cd(folder)
    main=pwd()

    file = DataFrame()
    battery_costs= DataFrame()
    
    file[!,"SOH_initial"] = soh_in[:]
    file[!,"SOH_final"] = soh_f[:]
    file[!,"Cumulated_Energy"] = cum_energy[:]
    file[!,"Degradation"] = degradation[:]
    file[!,"Net_Revenues"] = rev_stage[:]
    file[!,"Gain charge/discharge"] = gain[:]
    file[!,"Cost revamping"] = cost_rev[:]

    battery_costs[!,"Costs €/MWh"] = Battery_price[:]

    XLSX.writetable("Simulation.xlsx", overwrite=true,
        results = (collect(DataFrames.eachcol(file)),DataFrames.names(file)),
        costs = (collect(DataFrames.eachcol(battery_costs)),DataFrames.names(battery_costs))
    )

    cd(main)
        # ritorno nella cartella di salvataggio dati

    

    return println("Saved data in xlsx")
#end






