soh = [1 2 3 4 5]
NStages=length(soh)
NSteps=10
NStepsTot=NSteps*NStages

val=zeros(NStepsTot);
val2=zeros(NStepsTot);

for iStage=1:NStages
    for iStep= ((iStage-1)*NSteps+1):(iStage*NSteps)
        val[iStep] = iStep
        val2[iStep] = soh[iStage]*0.85
    end
end