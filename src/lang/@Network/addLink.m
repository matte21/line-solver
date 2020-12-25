function addLink(self, nodeA, nodeB)
% ADDLINK(NODEA, NODEB)

% Copyright (c) 2012-2021, Imperial College London
% All rights reserved.
numberOflinks = length(self.links);
self.links{1+numberOflinks, 1} = {nodeA, nodeB};
self.connMatrix(self.links{1+numberOflinks}{1}, self.links{1+numberOflinks}{2}) = 1;
end
