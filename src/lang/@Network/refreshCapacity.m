function [capacity, classcap, dropid] = refreshCapacity(self)
% [CAPACITY, CLASSCAP, DROPRULE] = REFRESHCAPACITY()

% Copyright (c) 2012-2021, Imperial College London
% All rights reserved.
M = getNumberOfStations(self);
K = getNumberOfClasses(self);
C = self.sn.nchains;
% set zero buffers for classes that are disabled
classcap = Inf*ones(M,K);
chaincap = Inf*ones(M,C);
capacity = zeros(M,1);
dropid = -ones(M,C); %DropStrategy.WaitingBuffer
sn = self.sn;
C = sn.nchains;
for c = 1:C
    classInChain = find(sn.chains(c,:));
    for r = classInChain
        chainCap = sum(sn.njobs(classInChain));
        for i=1:M
            station = self.getStationByIndex(i);
            if isnan(sn.rates(i,r))
                classcap(i,r) = 0;
                chaincap(i,r) = 0;
            elseif isa(station, 'Place')
                classcap(i,r) = min(station.classCap(r), station.cap);
                dropid(i,r) = DropStrategy.toId(station.input.inputJobClasses{r}{3});
            else
                classcap(i,r) = chaincap(i,c);
                chaincap(i,c) = chainCap;
                if station.classCap(r) >= 0
                    classcap(i,r) = min(classcap(i,r), station.classCap(r));
                end
                if station.cap >= 0
                    classcap(i,r) = min(classcap(i,r),station.cap);
                end
                if isa(station,'Queue')
                    dropid(i,r) = DropStrategy.toId(station.input.inputJobClasses{r}{3});
                end
            end
        end
    end
end
for i=1:M
    capacity(i,1) = min([sum(chaincap(i,:)),sum(classcap(i,:))]);
end
if ~isempty(self.sn) %&& isprop(self.sn,'cap')
    self.sn.cap = capacity;
    self.sn.classcap = classcap;
    self.sn.dropid = dropid;
end
end
