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
    CPX_PARAM_SCRIND::I = 0
    CPX_PARAM_PREIND::I = 0
    CPXPARAM_MIP_Tolerances_MIPGap::F = 1e-10
    CPX_PARAM_TILIM::I = 1000
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

    #runMode self defined reading of input 
    setInputParameters::B = true            #from .in file
 
    excel_savings::B = false

end

# Optimization problem
struct BuildStageProblem
    M::Any
    soc::Any
    charge::Any 
    discharge::Any
    auxiliary::Any
    deg1::Any
    deg2::Any
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
    aux::Any
    deg_neg::Any
    deg_pos::Any
    soh_final::Any
    soh_initial::Any
end
