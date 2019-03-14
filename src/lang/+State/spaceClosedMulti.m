function SS = spaceClosedMulti(M, N)
% Copyright (c) 2012-2019, Imperial College London
% All rights reserved.

% Copyright (c) 2012-2019, Imperial College London 
% All rights reserved.

R = length(N);
SS = State.spaceClosedSingle(M, N(1));
for r = 2:R
    SS = State.decorate(SS, State.spaceClosedSingle(M, N(r)));
end
end