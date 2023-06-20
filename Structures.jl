# STRUCTURES USED IN THE PROBLEM

# Input data
#-----------------------------------------------

# Input parameters 
@with_kw struct InputParam{F<:Float64,I<:Int}
    NYears::I                                     # Number of years
    NMonths::I
    NStages::I                                    # Number of stages of N months in the problem FORMULATION-- calcolato come NYears/NMonths*12
    NHoursStep::F                                 # Number of hours in each time step 
    NHoursStage::I                                 # Number of hours in each Stage (3-4-6 months)
    NSteps::I                                     # Number of steps in the NYeras --> NYears*8760/NHoursStep
    Big::F                                        # A big number
end

# Battery's characteristics
@with_kw struct BatteryParam{F<:Float64}
    max_Charge::F                                   # Batter's maximum capacity
    max_Discharge::F
    energy_Capacity::F                                  # Battery's maximum energy storage capacity
    Eff_charge::F
    Eff_discharge::F
    max_SOH::F
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
    A::Any
    Ncycle::Any
    soh_final::Any
    soh_new::Any
    deg::Any
end

struct Results
    obj::Any
    rev_stage::Any
    charge_bat::Any
    disc_bat::Any
    soc_bat::Any
    cum_energy::Any
    eq_cyc::Any
    degradation::Any
    soh_f::Any
    soh_in::Any
end
