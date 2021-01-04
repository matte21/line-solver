function [simDoc, section] = saveNumberOfServers(self, simDoc, section, ind)
% [SIMDOC, SECTION] = SAVENUMBEROFSERVERS(SIMDOC, SECTION, CURRENTNODE)

% Copyright (c) 2012-2021, Imperial College London
% All rights reserved.
sizeNode = simDoc.createElement('parameter');
sizeNode.setAttribute('classPath', 'java.lang.Integer');
sizeNode.setAttribute('name', 'maxJobs');

qn = self.getStruct;
valueNode = simDoc.createElement('value');
valueNode.appendChild(simDoc.createTextNode(int2str(qn.nservers(qn.nodeToStation(ind)))));

sizeNode.appendChild(valueNode);
section.appendChild(sizeNode);
end