#RUN FILE

# Calls the Packages used for the optimization problem
using JuMP
using Printf
using CPLEX
using MathOptInterface
using JLD
using TimerOutputs
using Distributions
using DataFrames
using XLSX
using Parameters
using Dates
using CSV
using Plots
using Combinatorics
using Rainflow

# Calls the other Julia files
include("Structures.jl")
include("SetInputParameters.jl")
include("ProblemFormulation.jl")
#include("dynamicProgramming.jl")
#include("Saving in xlsx.jl")
#include("dynamicProgramming given final and initial state.jl")
#include("Battery_Replacement_Costs.jl")
#include("Simulation.jl")

date = string(today())

# PREPARE INPUT DATA
to = TimerOutput()

@timeit to "Set input data" begin

  #Set run case - indirizzi delle cartelle di input ed output
  case = set_runCase()
  @unpack (DataPath,InputPath,ResultPath,CaseName) = case;

  # Set run mode (how and what to run) and Input parameters
  runMode = read_runMode_file()
  InputParameters = set_parameters(runMode, case)
  @unpack (NSteps, NHoursStep, Big)= InputParameters;

  # Set solver parameters (Cplex etc)
  SolverParameters = set_solverParameters()

  # Read power prices from a file [€/MWh]
  Power_prices=rand(1:100,NSteps)
  #Power_prices = read_csv("10years_hourlyprices.csv",case.DataPath)                    # 365 days x 48 valori alla mezz'ora
  #Battery_prices = read_csv("Cost_battery.csv",case.DataPath)                        # daily cost for battery replacement
  
  # Upload battery's characteristics
  Battery = set_battery_system(runMode, case)
  @unpack (max_Charge, max_Discharge, energy_Capacity, Eff_charge, Eff_discharge) = Battery;     

  # DEFINE STATE VARIABLES - STATE OF CHARGES SOC [MWh]
  #state_variables = define_state_variables(InputParameters, Battery)

  # Where and how to save the results
  FinalResPath= set_run_name(case, ResultPath, InputParameters)

end

#save input data
@timeit to "Save input" begin
    save(joinpath(FinalResPath,"CaseDetails.jld"), "case" ,case)
    save(joinpath(FinalResPath,"SolverParameters.jld"), "SolverParameters" ,SolverParameters)
    save(joinpath(FinalResPath,"InputParameters.jld"), "InputParameters" ,InputParameters)
    save(joinpath(FinalResPath,"BatteryCharacteristics.jld"), "BatteryCharacteristics" ,Battery)
    save(joinpath(FinalResPath,"PowerPrices.jld"),"PowerPrices",Power_prices)
end

@timeit to "Solve optimization problem" begin
  ResultsOptimization = BuildStageProblem(InputParameters, SolverParameters, Battery)
  #save(joinpath(FinalResPath, "optimization_results.jld"), "optimization_results", ResultsOptimization)
end

#= DYNAMIC PROGRAMMING
if runMode.dynamicProgramming
      ResultsDP = DP(InputParameters, SolverParameters, Battery, state_variables)
      save(joinpath(FinalResPath, "dp_Results.jld"), "dp_Results", ResultsDP)
    else
      println("Solved without dynamic programming.")
end
=#


#= SAVE DATA IN EXCEL FILES
if runMode.excel_savings
  cartella = "C:\\Users\\Utente\\Desktop\\Batteries\\Results"
  cd(cartella)
  Saving = data_saving(runMode,InputParameters,ResultsDP)
else
  println("Solved without saving results in xlsx format.")
end
=#

#end

print(to)



