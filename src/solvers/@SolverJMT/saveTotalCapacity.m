function [simDoc, section] = saveTotalCapacity(self, simDoc, section, ind)
% [SIMDOC, SECTION] = SAVETOTALCAPACITY(SIMDOC, SECTION, NODEIDX)

% Copyright (c) 2012-2021, Imperial College London
% All rights reserved.

qn = self.getStruct;
sizeNode = simDoc.createElement('parameter');
sizeNode.setAttribute('classPath', 'java.lang.Integer');
sizeNode.setAttribute('name', 'totalCapacity');
valueNode = simDoc.createElement('value');
if ~qn.isstation(ind) || isinf(qn.cap(qn.nodeToStation(ind)))
    valueNode.appendChild(simDoc.createTextNode(int2str(-1)));
else
    %valueNode.appendChild(simDoc.createTextNode(int2str(currentNode.cap)));
    valueNode.appendChild(simDoc.createTextNode(int2str(qn.cap(qn.nodeToStation(ind)))));
end

sizeNode.appendChild(valueNode);
section.appendChild(sizeNode);
end
