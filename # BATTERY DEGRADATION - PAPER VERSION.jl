
# VERSIONE PROF

#S1 = [40 0 0 0 0 0 0 73.6 80 80 80 80 80 80 80 80 80 80	80 0 0 0 0 0 0 0 0 0 0 73.6	80]

NSteps= 87600
S1=rand(1:100,NSteps)

soc=S1/maximum(S1)
NSteps=length(soc)

DoD=zeros(NSteps)

for i=1:NSteps
    DoD[i]=1-soc[i]
end

beta0= 4901
beta1= 1.98
beta2= 0.016

deg=zeros(NSteps)

for i=1:(NSteps-1)
    a1=beta0*(DoD[i+1]^(-beta1))*exp(beta2*(1-DoD[i+1]))                             # Equazione per calcolo numero cicli in funzione di DoD
    a0=beta0*(DoD[i]^(-beta1))*exp(beta2*(1-DoD[i]))

    deg[i]=0.5*abs(1/a1-1/a0)
end

DEG=sum(deg)

#SOC VIRTUALE
A=zeros(NSteps)

for j=1:(NSteps-1)
    A[j]=abs(soc[j+1]-soc[j])
end

A_sum= sum(A)
N_eq=0.5*A_sum/maximum(soc)                         # sostanzialmente quanti cicli da DoD0100% per poter "degradare" la batteria di quantità A

a1_eq=beta0*(1^(-beta1))*exp(beta2*(1-1))           #Ciclo completo con DoD=100
a0_eq=beta0*(0^(-beta1))*exp(beta2*(1-0))
deg_eq=abs(1/a1_eq-1/a0_eq)

DEG_1=deg_eq*N_eq
