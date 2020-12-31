function [AN] = getAvgArvRChain(self,A)
% [AN] = GETAVGARVRCHAIN(SELF,A)
% Return average arrival rates aggregated by chain
%
% Copyright (c) 2012-2021, Imperial College London
% All rights reserved.

qn = self.model.getStruct();
%if nargin == 1
%    [Q] = getAvgHandles(self);
%end
[ANclass] = getAvgArvR(self);

% compute average chain metrics
AN = zeros(qn.nstations, qn.nchains);
for c=1:qn.nchains
    inchain = find(qn.chains(c,:));
    for i=1:qn.nstations
        if ~isempty(ANclass)
            AN(i,c) = sum(ANclass(i,inchain));
        end
    end
end
end
