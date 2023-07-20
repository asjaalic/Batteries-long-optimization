
using JuMP,CPLEX

M = Model(CPLEX.Optimizer)
#M= Model(Gurobi.Optimizer)
NSteps=48
Eff_charge=0.9
Eff_discharge = 0.9
NHoursStep=1
energy_Capacity=1

@variable(M, 0 <= soc[iStep=1:NSteps+1] <= 10, base_name = "State of Charge")                # MWh   power_capacity
@variable(M, 0 <= charge[iStep=1:NSteps] <= 10, base_name = "Charge")                       # MAXCharge  - variabile decisionale : ricarico la batteria MW
@variable(M, 0 <= discharge[iStep=1:NSteps] <= 10, base_name = "Discharge")                 # MAXDischarge - variabile decisionale: scarico la batteria
@variable(M, value_next <= 10000, base_name = "Value next stage")

@objective(M,Max, sum(1*discharge[iStep]-1*charge[iStep] for iStep=1:NSteps))
         
# UPDATE CONSTRAINTS

#@constraint(M,Final_state_variable[iStep=NSteps], soc[iStep] + (Eff_charge*charge[iStep]-Eff_discharge*discharge[iStep])*NHoursStep == 0)
@constraint(M,State_variable[iStep=1:NSteps], soc[iStep] + (Eff_charge*charge[iStep]-Eff_discharge*discharge[iStep])*NHoursStep == soc[iStep+1])
@constraint(M,endingE[iStep=NSteps], soc[iStep] == 0)
@constraint(M,initialE[iStep=1], soc[iStep] == energy_Capacity)

optimize!(M)

@show value.(soc)
@show value.(charge)

@constraint(M, Binary_variables, xc+xd==1)
@constraint(M,Charging[iStep=1:NSteps],charge[iStep] <= 10*xc)
@constraint(M,Discharging[iStep=1:NSteps], discharge[iStep]<=10*xd)


ENV["GUROBI_HOME"] = "C:\\gurobi1002\\win64"
import Pkg
Pkg.add("Gurobi")
Pkg.build("Gurobi")

using JuMP,Gurobi