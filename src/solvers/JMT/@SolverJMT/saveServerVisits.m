function [simDoc, section] = saveServerVisits(self, simDoc, section)
% [SIMDOC, SECTION] = SAVESERVERVISITS(SIMDOC, SECTION)

% Copyright (c) 2012-2023, Imperial College London
% All rights reserved.
visitsNode = simDoc.createElement('parameter');
visitsNode.setAttribute('array', 'true');
visitsNode.setAttribute('classPath', 'java.lang.Integer');
visitsNode.setAttribute('name', 'numberOfVisits');

sn = self.getStruct;
numOfClasses = sn.nclasses;
for r=1:numOfClasses    
    refClassNode = simDoc.createElement('refClass');
    refClassNode.appendChild(simDoc.createTextNode(sn.classnames{r}));
    visitsNode.appendChild(refClassNode);
    
    subParameterNode = simDoc.createElement('subParameter');
    subParameterNode.setAttribute('classPath', 'java.lang.Integer');
    subParameterNode.setAttribute('name', 'numberOfVisits');
    
    valueNode2 = simDoc.createElement('value');
    valueNode2.appendChild(simDoc.createTextNode(int2str(1)));
    
    subParameterNode.appendChild(valueNode2);
    visitsNode.appendChild(subParameterNode);
    section.appendChild(visitsNode);
end
end
