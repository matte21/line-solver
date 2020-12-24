function connMatrix = getConnectionMatrix(self)
% [CONNMATRIX] = GETCONNECTIONMATRIX()

% Copyright (c) 2012-2020, Imperial College London
% All rights reserved.

% connection matrix
connMatrix = self.connMatrix;
if size(connMatrix,1)< self.getNumberOfNodes
    connMatrix(self.getNumberOfNodes,1)=0;
end
if size(connMatrix,2)< self.getNumberOfNodes
    connMatrix(1,self.getNumberOfNodes)=0;
end
end
