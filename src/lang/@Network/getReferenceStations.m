function refstat = getReferenceStations(self)
% REFSTAT = GETREFERENCESTATIONS()

% Copyright (c) 2012-2021, Imperial College London
% All rights reserved.

K = getNumberOfClasses(self);
refstat = zeros(K,1);
for k=1:K
    refstat(k,1) =  findstring(getStationNames(self),self.classes{k}.reference.name);
end
end
