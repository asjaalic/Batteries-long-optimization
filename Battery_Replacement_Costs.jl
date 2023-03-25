# POST-OPTIMIZATION PROBLEM EVALUATION : RAINFLOW COUNTING ALGORITHM AND EVALUATION OF DAILY COST FOR BATTERY REPLACEMENT

#=function battery_replacement(
    InputParameters::InputParam,
    Battery::BatteryParam,
    ResultsDP::Results_dp)
=#
using Rainflow
using Plots

    println("Battery replacement evaluation")

    @unpack (NStages, NStates, NSteps, NHoursStage, NHoursStep, Big) = InputParameters
    @unpack (power_Capacity, energy_Capacity, Eff_charge, Eff_discharge) = Battery                  #MAXCharge, MAXDischarge,
    @unpack (soc, gain,final_soc,final_gain) = ResultsDP;

    totCycles = zeros(NStages,NStates,NStates);
    costBattery = zeros(NStages,NStates,NStates);
    final_gain = zeros(NStages,NStates,NStates);
    Battery_price = 25         #€/equivalent_cycle

    # Rainflow counting algorithm for each day

    for t=1:NStages
        for iState=1:NStates
            for jState=1:NStates

                signal = soc[t,iState,jState,:]
                extremes,step = sort_peaks(signal)
                cycles=count_cycles(extremes,step)
                num=length(cycles)
                for j=1:num
                    totCycles[t,iState,jState]=totCycles[t,iState,jState]+cycles[j].count
                end
                costBattery[t,iState,jState] = totCycles[t,iState,jState]*Battery_price
                final_gain[t,iState,jState] = gain[t,iState,jState]-costBattery[t,iState,jState]
            end
        end
    end
    
    return Replacement(
        totCycles,
        costBattery,
        final_gain,
    )
#end


signal = soc[20,1,10,:]
plot(signal,size=(1000,600))
slope = diff(signal)
slope[1:end-1]
slope[2:end]

slope[1:end-1].*slope[2:end]

extremes,step = sort_peaks(signal)
scatter!(step,extremes)
cycles=count_cycles(extremes,step)

a=length(cycles)

final_cycles = []

for i=1:a
    if cycles[i].range!=0
        println(cycles[i])
        println("Position $i")
        append!(final_cycles,i)
    end
end


typeof(cycles)

push!(final_cycles, cycles[18])


signal2 = soc[24,10,10,:]
plot(signal2)
extremes,t = sort_peaks_new(signal2)
scatter!(t,extremes)
cycles2=count_cycles(extremes,t)

a=length(cycles2)
final_cycles2 = []

for i=1:a
    if cycles2[i].range!=0
        println(cycles[i])
        println("Position $i")
        push!(final_cycles2,cycles2[i])
    end
end

function sort_peaks_new(signal::AbstractArray{Float64,1}, dt=collect(1.:length(signal)))
    slope = diff(signal)
    # Determines if the point is local extremum
    is_extremum = vcat(true, (slope[1:end-1].*slope[2:end]).<=0., true)
    return signal[is_extremum] , dt[is_extremum]
end


s = [2.3, 4, -3, -3,-3, 5, 10, 10, 2, 3, -5, 9]
plot(s,size=(1000,600))
extremes,t = sort_peaks(s)
scatter!(t,extremes)


a = randn(10)

function counting_cycles(peaks::Array{Float64,1},t::Array{Float64,1})
    points =copy(peaks)
    time = copy(t)

    values=[]
    cycles=Cycle[]
    firstSet=[]
    nextSet=[]

    currentIndex=1
    nextIndex=2
    append!(values,points[currentIndex],points[nextIndex])
              # Set Z to the first point of the profile
    
    while length(points)>(currentIndex+1)   #inizio il cicl finchè non ho passato tutti i punti    WHILE
        Z=values[1]
        #if out of data, count the remaining two pooints as half cycl
        if currentIndex+2>length(points)
            push!(cycles,cycle(0.5,points[currenIndex],tme[currentIndex], points[currentIndex+1], points[currentIndex+1]))
        else

            if length(values)<3 
                append!(values,points[nextIndex+1])
            else    #se abbiamo più di 3 punti
                append!(firstSet,points[currentIndex],points[currentIndex+1])       # A e B
                append!(nextSet,points[nextIndex],points[nextIndex+1])              # B e C
                firstSeg=abs(points[currentIndex+1]-points[currentIndex])           # Calcolo altezza A-B
                nextSeg=abs(points[currentIndex+2]-points[currentIndex+1])          # Calcolo altezza B-C

                if nextSeg>firstSeg 

                    if (Z in firstSet)
                        popfirst!(values)
                        popfirst!(firstSet)
                        push!(cycles,cycle(0.5, points[currentIndex], time[currentIndex],points[currentIndex], time[currentIndex]))
                        currentIndex=currentIndex+1
                        nextIndex=nextIndex+1
                    else
                        push!(cycles,cycle(1.0, points[currentIndex], time[currentIndex],points[currentIndex], time[currentIndex]))
                        deleteat!(values,points[currentIndex],points[currentIndex+1])
                    end

                else
                    # Read the next value
                    currentIndex=currentIndex+1
                    nextIndex=nextIndex+1
                end
        

            end
    end

end


function counting_cycles(peaks::Array{Float64,1},t::Array{Float64,1})
    points =copy(peaks)
    time = copy(t)

    values=[]
    cycles=Cycle[]
    firstSet=[]
    nextSet=[]

    currentIndex=1
    nextIndex=2

    append!(values,points[currentIndex],points[nextIndex])
              # Set Z to the first point of the profile
    
    while length(points)>(currentIndex+1)   #inizio il cicl finchè non ho passato tutti i punti    WHILE
        
        Z=values[1]

        #if out of data, count the remaining two pooints as half cycl
        if currentIndex+2>length(points)
            push!(cycles,cycle(0.5,points[currenIndex],tme[currentIndex], points[currentIndex+1], points[currentIndex+1]))
        else

            if length(values)<3 
                append!(values,points[nextIndex+1])
            else    #se abbiamo più di 3 punti
                
                append!(firstSet,values[end-2],values[end-1])
                append!(nextSet,values[end-1],values[end])              # B e C
                firstSeg=abs(firsSet[2]-firstSet[1])           # Calcolo altezza A-B
                nextSeg=abs(nextSet[2]-nextSet[1])          # Calcolo altezza B-C

                if nextSeg>firstSeg 

                    if (Z in firstSet)
                        popfirst!(values)
                        popfirst!(firstSet)
                        push!(cycles,cycle(0.5, points[currentIndex], time[currentIndex],points[currentIndex], time[currentIndex]))
                        currentIndex=currentIndex+1     # stiamo procedendo
                        nextIndex=nextIndex+1           # mi serve per contare e aggiungere al vettore values il numero successivo
                    else
                        push!(cycles,cycle(1.0, points[currentIndex], time[currentIndex],points[currentIndex], time[currentIndex]))
                        deleteat!(values,values[end-2],values[end-1])
                    end
                else
                    # Read the next value
                    currentIndex=currentIndex+1
                    nextIndex=nextIndex+1
                end

            end
        end
    end

end

