function addRegion(self, nodes)
% ADDREGION(NODES)

% Copyright (c) 2012-2022, Imperial College London
% All rights reserved.

%
fcr = FiniteCapacityRegion(nodes, self.classes);
self.regions{end+1,1} = fcr;
end
