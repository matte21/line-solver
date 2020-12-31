function [simElem, simDoc] = saveLinks(self, simElem, simDoc)
% [SIMELEM, SIMDOC] = SAVELINKS(SIMELEM, SIMDOC)

% Copyright (c) 2012-2021, Imperial College London
% All rights reserved.
qn = self.getStruct;

[I,J]=find(qn.connmatrix);
for k=1:length(I)
    i=I(k);
    j=J(k);
    connectionNode = simDoc.createElement('connection');
    connectionNode.setAttribute('source', qn.nodenames(i));
    connectionNode.setAttribute('target', qn.nodenames(j));
    simElem.appendChild(connectionNode);
end
end
