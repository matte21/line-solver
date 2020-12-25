function self = updateEnsemble(self, isBuild)
% SELF = UPDATEENSEMBLE(ISBUILD)

% Copyright (c) 2012-2021, Imperial College London
% All rights reserved.

if isBuild
    self = self.buildEnsemble();
else
    self = self.refreshEnsemble();
end

end
