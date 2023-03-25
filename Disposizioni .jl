# DISPOSIZIONI CON RIPETIZIONE
using CSV
using Tables
using TimerOutputs

states=[1,2,3,4,5]
n_states=length(states)
stages=13
intervallo = 24/(stages-1)
combo=n_states^stages
count=0
chargeTime = 2                  # 2 = 50% max di carica/scarica tra uno stage e l'altro (dipende da quanti stati e stage ho) - 4 vuol dire 100% max
check = true

scen=zeros(Int,stages)                          
to =TimerOutput()
#FinalResPath="C:\\BATTERIES"

@timeit to "Collect combinations" begin
    
    for a=1:n_states
        c1=states[a]
        for b=1:n_states
            c2=states[b]
            for c=1:n_states
                c3=states[c]
                for d=1:n_states
                    c4=states[d]
                    for e=1:n_states
                        c5=states[e]
                        for f=1:n_states
                            c6=states[f]
                            for g=1:n_states
                                c7=states[g]
                                for h=1:n_states
                                    c8=states[h]
                                    for i=1:n_states
                                        c9=states[i]
                                        for j=1:n_states
                                            c10=states[j]
                                            for k=1:n_states
                                                c11=states[k]
                                                for l=1:n_states
                                                    c12=states[l]
                                                    for m=1:n_states
                                                        c13=states[m]
                                                        #=for n=1:n_states
                                                            c14=states[n]
                                                            for o=1:n_states
                                                                c15=states[o]
                                                                for p=1:n_states
                                                                    c16=states[p]
                                                                    for q=1:n_states
                                                                        c17=states[q]
                                                                        for r=1:n_states
                                                                            c18=states[r]
                                                                            for s=1:n_states
                                                                                c19=states[s]
                                                                                for t=1:n_states
                                                                                    c20=states[t]
                                                                                    for u=1:n_states
                                                                                        c21=states[u]
                                                                                        for w=1:n_states
                                                                                            c22=states[w]
                                                                                            for x=1:n_states
                                                                                                c23=states[x]
                                                                                                for y=1:n_states
                                                                                                    c24=states[y]
                                                                                                    for z=1:n_states
                                                                                                        c25=states[z]
                                                                                                        =#
                                                                                                        
                                                                                                        scen[1]=c1
                                                                                                        scen[2]=c2
                                                                                                        scen[3]=c3
                                                                                                        scen[4]=c4
                                                                                                        scen[5]=c5
                                                                                                        scen[6]=c6
                                                                                                        scen[7]=c7
                                                                                                        scen[8]=c8
                                                                                                        scen[9]=c9
                                                                                                        scen[10]=c10
                                                                                                        scen[11]=c11
                                                                                                        scen[12]=c12
                                                                                                        scen[13]=c13
                                                                                                        #=scen[14]=c14
                                                                                                        scen[15]=c15
                                                                                                        scen[16]=c16
                                                                                                        scen[17]=c17
                                                                                                        scen[18]=c18
                                                                                                        scen[19]=c19
                                                                                                        scen[20]=c20
                                                                                                        scen[21]=c21
                                                                                                        scen[22]=c22
                                                                                                        scen[23]=c23
                                                                                                        scen[24]=c24
                                                                                                        scen[25]=c25 =#
                                                                                                        
                                                                                                        #=
                                                                                                            for temp=1:n_states-1                                                                                        
                                                                                                                variable = scen[temp+1]-scen[temp]
                                                                                                                println("Variabile ", variable)

                                                                                                                if variable > chargeTime || variable < -chargeTime
                                                                                                                    check = false
                                                                                                                    break
                                                                                                                end
                                                                                                            end
                                                                                                        =# 
                                                                                                    
                                                                                                        println("Vettore: ",scen, "check: ",check)

                                                                                                        count =count+1
                                                                                                        print("\033c")
                                                                                                        println("Index:",count)
                                                                                                        if check == true
                                                                                                            CSV.write("Combo_with_filter_h$intervallo.csv",Tables.table(collect(scen')), writeheader=false, append =true)
                                                                                                        else
                                                                                                            check = true
                                                                                                        end

                                                                                                        #=save(joinpath(FinalResPath, "Combinations_prova1.jld"), "Combo", scen')

                                                                                                    end
                                                                                                end
                                                                                            end
                                                                                        end
                                                                                    end
                                                                                end
                                                                            end
                                                                        end
                                                                    end
                                                                end
                                                            end
                                                        end =#
                                                    end 
                                                end
                                            end 
                                        end
                                    end
                                end 
                            end
                        end 
                    end
                end
            end
        end 
    end

end









