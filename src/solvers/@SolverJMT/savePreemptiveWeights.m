function [simDoc, section] = savePreemptiveWeights(self, simDoc, section, ind)
% [SIMDOC, SECTION] = SAVEPREEMPTIVEWEIGHTS(SIMDOC, SECTION, NODEIDX)

% Copyright (c) 2012-2021, Imperial College London
% All rights reserved.
visitsNode = simDoc.createElement('parameter');
visitsNode.setAttribute('array', 'true');
visitsNode.setAttribute('classPath', 'java.lang.Double');
visitsNode.setAttribute('name', 'serviceWeights');

qn = self.getStruct;
numOfClasses = qn.nclasses;
i = qn.nodeToStation(ind);
for r=1:numOfClasses
    refClassNode = simDoc.createElement('refClass');
    refClassNode.appendChild(simDoc.createTextNode(qn.classnames{r}));
    visitsNode.appendChild(refClassNode);
    
    subParameterNode = simDoc.createElement('subParameter');
    subParameterNode.setAttribute('classPath', 'java.lang.Double');
    subParameterNode.setAttribute('name', 'serviceWeight');
    
    valueNode2 = simDoc.createElement('value');    
    %switch qn.schedid(i)
        %case SchedStrategy.ID_PS
        %    valueNode2.appendChild(simDoc.createTextNode(int2str(1)));
        %case {SchedStrategy.ID_DPS, SchedStrategy.ID_GPS}
            valueNode2.appendChild(simDoc.createTextNode(num2str(qn.schedparam(i,r))));
    %end
    
    subParameterNode.appendChild(valueNode2);
    visitsNode.appendChild(subParameterNode);
    section.appendChild(visitsNode);
end
end
