# BATTERY DEGRADATION - PAPER VERSION
beta0= 4901
beta1=1.98
beta2=0.016

NSteps= 8064
soc=rand(1:100, NSteps)/100
dod=zeros(NSteps)

for i=1:NSteps
    dod[i]=1-soc[i]
end

Ncycles=zeros(NSteps)
for i=1:NSteps
    Ncycles[i]=beta0*(dod[i])^(-beta1)*exp(beta2*(soc[i]))
end

deg=zeros(NSteps-1)
for i=1:NSteps-1
    deg[i]=0.5*abs(1/Ncycles[i+1]-1/Ncycles[i])
end

tot_deg=sum(deg)

var_soc=zeros(NSteps-1)

for i=1:NSteps-1
    var_soc[i]=abs(soc[i+1]-soc[i])
end

E=sum(var_soc)
maximum(soc)

rand(1:100,87600)
