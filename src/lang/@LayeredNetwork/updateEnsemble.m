function self = updateEnsemble(self, isBuild)
% SELF = UPDATEENSEMBLE(ISBUILD)

% Copyright (c) 2012-2021, Imperial College London
% All rights reserved.

if isBuild
    self = buildEnsemble(self);
else
    self = refreshEnsemble(self);
end

end
