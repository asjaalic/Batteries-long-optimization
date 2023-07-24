# EXCEL SAVINGS
#using DataFrames
#using XLSX

function data_saving(InputParameters::InputParam,ResultsOpt::Results)

    @unpack (NYears, NMonths, NStages, NSteps, Big, NHoursStep, NHoursStage) = InputParameters;
    @unpack (charge,discharge, soc, soh_final, soh_initial, revenues_per_stage, deg, soc_aux, p_aux, d, deg, d_1,d_2,deg_1,deg_2,u, gain_stage, cost_rev, deg_stage) = ResultsOpt;        #cum_energy,
    @unpack (energy_Capacity, Eff_charge, Eff_discharge, max_SOH, min_SOH ) = Battery ; 

    hour=string(now())
    a=replace(hour,':'=> '-')

    nameF= " VARIABILI BINARIE "
    nameFile="Final results decreasing prices"

    folder = "$nameF"
    mkdir(folder)
    cd(folder)
    main=pwd()

    general = DataFrame()
    battery_costs= DataFrame()
    
    general[!,"SOH_initial"] = soh_initial[:]
    general[!,"SOH_final"] = soh_final[:]
    general[!,"Degradation"] = deg_stage[:]
    general[!,"Net_Revenues"] = revenues_per_stage[:]
    general[!,"Gain charge/discharge"] = gain_stage[:]
    general[!,"Cost revamping"] = cost_rev[:]

    battery_costs[!,"Costs €/MWh"] = Battery_price[:]

    XLSX.writetable("$nameFile.xlsx", overwrite=true,                                       #$nameFile
    results_stages = (collect(DataFrames.eachcol(general)),DataFrames.names(general)),
    costs = (collect(DataFrames.eachcol(battery_costs)),DataFrames.names(battery_costs)),
    )

    for iStage=1:NStages
        steps = DataFrame()

        steps[!,"Step"] = ((iStage-1)*NHoursStage+1):(NHoursStage*iStage)
        steps[!,"SOC"] = soc[((iStage-1)*NHoursStage+1):(NHoursStage*iStage)]
        steps[!, "Charge MW"] = charge[((iStage-1)*NHoursStage+1):(NHoursStage*iStage)]
        steps[!, "Discharge MW"] = discharge[((iStage-1)*NHoursStage+1):(NHoursStage*iStage)]
        steps[!, "d"] = d[((iStage-1)*NHoursStage+1):(NHoursStage*iStage)]
        steps[!, "d_1"] = d_1[((iStage-1)*NHoursStage+1):(NHoursStage*iStage)]
        steps[!, "d_2"] = d_2[((iStage-1)*NHoursStage+1):(NHoursStage*iStage)]
        steps[!, "Deg"] = deg[((iStage-1)*NHoursStage+1):(NHoursStage*iStage)]
        steps[!, "Deg_1"] = deg_1[((iStage-1)*NHoursStage+1):(NHoursStage*iStage)]
        steps[!, "Deg_2"] = deg_2[((iStage-1)*NHoursStage+1):(NHoursStage*iStage)]
        steps[!, "Binary u"] = u[((iStage-1)*NHoursStage+1):(NHoursStage*iStage)]
        steps[!, "AUX"] = soc_aux[((iStage-1)*NHoursStage+1):(NHoursStage*iStage)]
        steps[!, "P_AUX k"] = p_aux[((iStage-1)*NHoursStage+1):(NHoursStage*iStage)]
        steps[!, "Energy_prices €/MWh"] = Power_prices[((iStage-1)*NHoursStage+1):(NHoursStage*iStage)]

        XLSX.writetable("$iStage stage.xlsx", overwrite=true,                                       #$nameFile
        results_steps = (collect(DataFrames.eachcol(steps)),DataFrames.names(steps)),
    )

    end

    cd(main)             # ritorno nella cartella di salvataggio dati


    return println("Saved data in xlsx")
end






