# STRUCTURES USED IN THE PROBLEM

# Input data
#-----------------------------------------------

# Input parameters 
@with_kw struct InputParam{F<:Float64,I<:Int}
    # NStages::I                                    #Number of stages in the problem FORMULATION
    # NStates::I                                    #Number of possible states for each stage
    NSteps::I                                     #Number of steps within each stage 
    # NHoursStage::I                                #Number of hours in one stage
    NHoursStep::F                                 #Number of hours in each time step within a stage
    Big::F                                        #A big number
end

# Battery's characteristics
@with_kw struct BatteryParam{F<:Float64}
    max_Charge::F                                   # Batter's maximum capacity
    max_Discharge::F
    energy_Capacity::F                                  # Battery's maximum energy storage capacity
    Eff_charge::F
    Eff_discharge::F
end
  
# solver parameters
@with_kw struct SolverParam{F<:Float64,I<:Int}
    CPX_PARAM_SCRIND::I = 0
    CPX_PARAM_PREIND::I = 0
    CPXPARAM_MIP_Tolerances_MIPGap::F = 1e-10
    CPX_PARAM_TILIM::I = 120
    CPX_PARAM_THREADS ::I = 1
end
  
# Indirizzi cartelle
@with_kw struct caseData{S<:String}
    DataPath::S
    InputPath::S
    ResultPath::S
    CaseName::S
end

# runMode Parameters
@with_kw mutable struct runModeParam{B<:Bool}

    # Solver settings
    solveMIP::B = false    #If using SOS2

    batterySystemFromFile::B = true
  
    # SDP settings
    solveSDP::B = true
    DebugSP::B = false #Option to save results from each time decision problem is solved in SDP
    #useWaterValues::B = false # option to start SDP using exist
    #readSDPResults::B = false
  
    # SIM settings
    dynamicProgramming::B= true
    simulate::B = true
    parallellSim::B = false
   
    #runMode self defined reading of input 
    setInputParameters::B = true            #from .in file
 
    createMarkovModel::B = true              #from input file
    #markovModelFromDataStorage::B = false    #from previous result files
  
    drawScenarios::B = true
    drawOutofSampleScen::B = false
    useScenariosFromDataStorage::B = false   #from previous result files
    useHistoricScen::B = false               #from input file 

    battery_replacement::B = false           

    excel_savings::B = false

end

# Optimization problem
struct BuildStageProblem
    model::Any
    #value_next::Any
    soc::Any
    charge::Any
    discharge::Any
    #Final_state_variable::Any
    #State_variable::Any
    #Value_next_stage::Any
    energy::Any
end

#=
struct Results_dp
    soc::Any
    charge::Any
    discharge::Any
    gain::Any
    power_price::Any
    cost_charge::Any
    gain_discharge::Any
    optimalValueStates::Any
    optimalfromState::Any
    final_soc::Any
    final_charges::Any
    final_discharges::Any
    final_cost_charge::Any
    final_gain_discharge::Any
    final_gain::Any
    final_values::Any
    optimalState::Any
    val::Any
end

struct Replacement
    totCycles::Any
    costBattery::Any
    final_gain::Any
end

struct states
    seg::Any
    maxEnergy::Any
end
=#
