# EXCEL SAVINGS
#using DataFrames
#using XLSX

function data_saving(InputParameters::InputParam,ResultsOpt::Results)

    @unpack (NYears, NMonths, NStages, NSteps, Big, NHoursStep, NHoursStage) = InputParameters;
    #@unpack (charge_bat,disc_bat, soc_bat,eq_cyc, soh_f, soh_in,rev_stage, degradation, gain, cost_rev, aux_c, aux_d) = ResultsOpt;        #cum_energy,
    @unpack (charge_bat,disc_bat, soc_bat, soh_f, soh_in, rev_stage, deg_stage,deg_ch,deg_dis, gain, cost_rev) = ResultsOpt;        #cum_energy,
    @unpack (energy_Capacity, Eff_charge, Eff_discharge, max_SOH, min_SOH ) = Battery ; 

    hour=string(now())
    a=replace(hour,':'=> '-')

    nameF= "old$NYears y, $NMonths monStage, $NStages stages, $NSteps steps, $max_SOH maxSOH, $min_SOH minSOH, $energy_Capacity SOC $a"
    nameFile="Final results decreasing prices"

    folder = "$nameF"
    mkdir(folder)
    cd(folder)
    main=pwd()

    general = DataFrame()
    battery_costs= DataFrame()
    
    general[!,"SOH_initial"] = soh_in[:]
    general[!,"SOH_final"] = soh_f[:]
    general[!,"Degradation"] = deg_stage[:]
    general[!,"Net_Revenues"] = rev_stage[:]
    general[!,"Gain charge/discharge"] = gain[:]
    general[!,"Cost revamping"] = cost_rev[:]

    battery_costs[!,"Costs €/MWh"] = Battery_price[:]

    XLSX.writetable("$nameFile.xlsx", overwrite=true,                                       #$nameFile
    results_stages = (collect(DataFrames.eachcol(general)),DataFrames.names(general)),
    costs = (collect(DataFrames.eachcol(battery_costs)),DataFrames.names(battery_costs)),
    )

    for iStage=1:NStages
        steps = DataFrame()

        steps[!,"Step"] = ((iStage-1)*NHoursStage+1):(NHoursStage*iStage)
        steps[!,"SOC"] = soc_bat[((iStage-1)*NHoursStage+1):(NHoursStage*iStage)]
        steps[!, "Charge MW"] = charge_bat[((iStage-1)*NHoursStage+1):(NHoursStage*iStage)]
        steps[!, "Deg charge MW"] = deg_ch[((iStage-1)*NHoursStage+1):(NHoursStage*iStage)]
        steps[!, "Discharge MW"] = disc_bat[((iStage-1)*NHoursStage+1):(NHoursStage*iStage)]
        steps[!, "Deg discharge MW"] = deg_dis[((iStage-1)*NHoursStage+1):(NHoursStage*iStage)]
        steps[!, "Energy_prices €/MWh"] = Power_prices[((iStage-1)*NHoursStage+1):(NHoursStage*iStage)]

        XLSX.writetable("$iStage stage.xlsx", overwrite=true,                                       #$nameFile
        results_steps = (collect(DataFrames.eachcol(steps)),DataFrames.names(steps)),
    )

    end

    cd(main)             # ritorno nella cartella di salvataggio dati


    return println("Saved data in xlsx")
end






