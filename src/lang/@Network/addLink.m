function addLink(self, nodeA, nodeB)
% ADDLINK(NODEA, NODEB)

% Copyright (c) 2012-2021, Imperial College London
% All rights reserved.
self.links{end+1, 1} = {nodeA, nodeB};
self.connMatrix(self.links{end}{1}.index, self.links{end}{2}.index) = 1;
end
