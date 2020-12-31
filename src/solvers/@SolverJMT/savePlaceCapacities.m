function [simDoc, section] = savePlaceCapacities(self, simDoc, section, ind)
% [SIMDOC, SECTION] = SAVEPLACECAPACITY(SIMDOC, SECTION, NODEIDX)

% Copyright (c) 2012-2021, Imperial College London
% All rights reserved.


placeCapacityNode = simDoc.createElement('parameter');
placeCapacityNode.setAttribute('array', 'true');
placeCapacityNode.setAttribute('classPath', 'java.lang.Integer');
placeCapacityNode.setAttribute('name', 'capacities');
qn = self.getStruct;
numOfClasses = qn.nclasses;
i = qn.nodeToStation(ind);
for r=1:numOfClasses
    refClassNode = simDoc.createElement('refClass');
    refClassNode.appendChild(simDoc.createTextNode(qn.classnames{r}));
    placeCapacityNode.appendChild(refClassNode);
    
    subParameterNode = simDoc.createElement('subParameter');
    subParameterNode.setAttribute('classPath', 'java.lang.Integer');
    subParameterNode.setAttribute('name', 'capacity');
    
    valueNode2 = simDoc.createElement('value');
    if isinf(qn.classcap(i,r))
        valueNode2.appendChild(simDoc.createTextNode(int2str(-1)));
    else
        valueNode2.appendChild(simDoc.createTextNode(int2str(qn.classcap(i,r))));
    end
    
    subParameterNode.appendChild(valueNode2);
    placeCapacityNode.appendChild(subParameterNode);
end
section.appendChild(placeCapacityNode);
end
