# STRUCTURES USED IN THE PROBLEM

# Input data
#-----------------------------------------------

# Input parameters 
@with_kw struct InputParam{F<:Float64,I<:Int}
    NYears::F                                     # Number of years
    NMonths::I
    NStages::I                                    # Number of stages of N months in the problem FORMULATION-- calcolato come NYears/NMonths*12
    NHoursStep::F                                 # Number of hours in each time step 
    NHoursStage::I                                 # Number of hours in each Stage (3-4-6 months)
    NSteps::I                                     # Number of steps in the NYeras --> NYears*8760/NHoursStep
    Big::F                                        # A big number
    conv::F                                       # A small number for degradation convergence
end

# Battery's characteristics
@with_kw struct BatteryParam{F<:Float64,I<:Int}
    energy_Capacity::F                             # Battery's maximum energy storage capacity
    Eff_charge::F                                  # Battery's efficiency for charging operation
    Eff_discharge::F                               # Battery's efficiency for discharging operation
    max_SOH::F                                     # Maximum SOH that can be achieved because of volume issues
    min_SOH::F                                     # Minimum SOH to be respected by contract
    Nfull::I                                       # Maximum number of full cycles for DoD=100%
    max_disc::I                                   # Discretization charging/discharging vector
end
  
# solver parameters
@with_kw struct SolverParam{F<:Float64,I<:Int}
    MIPGap::F 
    MIPFocus::I
    Method::F
    Cuts::F
    Heuristics::F
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
    solveMIP::B     #If using SOS2

    batterySystemFromFile::B 

    #runMode self defined reading of input 
    setInputParameters::B             #from .in file
 
    excel_savings::B 

end

# Optimization problem
struct BuildStageProblem
    M::Any
    soc::Any
    charge::Any 
    discharge::Any
    SOC_aux::Any
    P_aux::Any
    d::Any
    deg::Any
    #u::Any
    u1::Any
    u2::Any
    d_1::Any
    d_2::Any
    d_3::Any
    deg_1::Any
    deg_2::Any
    deg_3::Any
    soh_final::Any
    soh_new::Any
end

struct Results
    objective::Any
    revenues_per_stage::Any
    gain_stage::Any
    cost_rev::Any
    deg_stage::Any
    soc::Any
    charge::Any
    discharge::Any
    soc_aux::Any
    p_aux::Any
    d::Any
    deg::Any
    d_1::Any
    d_2::Any
    d_3::Any
    deg_1::Any
    deg_2::Any
    deg_3::Any
    #u::Any
    u1::Any
    u2::Any
    soh_final::Any
    soh_initial::Any
end
