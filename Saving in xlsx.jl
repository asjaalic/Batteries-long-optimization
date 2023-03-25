# EXCEL SAVINGS
#using DataFrames
#using XLSX

function data_saving(runMode::runModeParam, InputParameters::InputParam,ResultsDP::Results_dp)

    @unpack (battery_replacement) = runMode
    @unpack (NStates,NSteps,NHoursStep, NStages) = InputParameters
    @unpack (charge,discharge,soc,cost_charge,gain_discharge,power_price, val) = ResultsDP

    hour=string(now())
    a=replace(hour,':'=> '-')

    nameF= "$NStages days, $NStates states, $NSteps steps, $a"

    if battery_eplacement
        nameF=nameF,"with battery replacement"
    end

    folder = "$nameF"
    mkdir(folder)
    cd(folder)
    main=pwd()


    for t=NStages:-1:1
        nameF2="Day $t"
        folder2="$nameF2"
        mkdir(folder2)
        cd(folder2)

        for iState=1:NStates
            char = DastaFrame()
            dischar = DataFrame()
            price = DataFrame()
            stateofcharge = DataFrame()
            cost_char = DataFrame()
            gain_dischar = DataFrame()

            for jState=1:NStates
                char[!,"jState_$jState"] = charge[t,iState,jState,:]
                dischar[!,"jState_$jState"] = discharge[t,iState,jState,:]
                stateofcharge[!,"jState_$jState"] = soc[t,iState,jState,:]
                cost_char[!,"jState_$jState"] = cost_charge[t,iState,jState,:]
                gain_dischar[!,"jState_$jState"] = gain_discharge[t,iState,jState,:]
                price[!,"jState_$jState"] = power_price[t,:]
            end

            XLSX.writetable("Day_$t,InitialState_$iState.xlsx", overwrite=true,
                Charge_MW = (collect(DataFrames.eachcol(char)),DataFrames.names(char)),
                Disharge_MW = (collect(DataFrames.eachcol(dischar)),DataFrames.names(dischar)),
                SOC_MWh = (collect(DataFrames.eachcol(stateofcharge)),DataFrames.names(stateofcharge)),
                Cost_charge_€ = (collect(DataFrames.eachcol(cost_char)),DataFrames.names(cost_char)),
                Gain_discharge_€ = (collect(DataFrames.eachcol(gain_dischar)),DataFrames.names(gain_dischar)),
                Prices_€alMWh = (collect(DataFrames.eachcol(price)),DataFrames.names(price))
            )

        end
        cd(main)
        # ritorno nella cartella di salvataggio dati

    end

    cd(main)
    folder3 = "Optimal Values"
    mkdir(folder3)
    cd(folder3)

    for t=NStages:-1:1

        values = DataFrame()

        for jState=1:NStates
            values[!,"FromState $jState"] = ResultsDP.val[t,:,jState]
        end

            XLSX.writetable("OptimalValues day $t.xlsx", overwrite=true,
                Values_€ = (collect(DataFrames.eachcol(values)),DataFrames.names(values)),
            )
    #cd(indirizzo)
    end

    return println("Saved data in xlsx")
end






