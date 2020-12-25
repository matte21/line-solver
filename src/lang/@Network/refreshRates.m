function [rates, scv] = refreshRates(self)
% [RATES, SCV] = REFRESHRATES()

% Copyright (c) 2012-2021, Imperial College London
% All rights reserved.

M = self.getNumberOfStations();
K = self.getNumberOfClasses();
hasOpenClasses = self.hasOpenClasses;
rates = zeros(M,K);
stations = self.stations;
% determine rates
for i=1:M
    for r=1:K
        switch stations{i}.server.className
            case 'ServiceTunnel'
                % do nothing
                switch class(stations{i})
                    case 'Source'
                        if isempty(stations{i}.input.sourceClasses{r}) || stations{i}.input.sourceClasses{r}{end}.isDisabled
                            rates(i,r) = NaN;
                            scv(i,r) = NaN;
                        elseif stations{i}.input.sourceClasses{r}{end}.isImmediate
                            rates(i,r) = Distrib.InfRate;
                            scv(i,r) = 0;
                        else
                            rates(i,r) = 1/stations{i}.input.sourceClasses{r}{end}.getMean();
                            scv(i,r) = stations{i}.input.sourceClasses{r}{end}.getSCV();
                        end
                    case 'Join'
                        rates(i,r) = Inf;
                        scv(i,r) = 0;
                end
            otherwise
                if ~hasOpenClasses || i ~= self.getIndexSourceStation
                    if isempty(stations{i}.server.serviceProcess{r}) || stations{i}.server.serviceProcess{r}{end}.isDisabled
                        rates(i,r) = NaN;
                        scv(i,r) = NaN;
                    elseif stations{i}.server.serviceProcess{r}{end}.isImmediate
                        rates(i,r) = Distrib.InfRate;
                        scv(i,r) = 0;
                    else
                        rates(i,r) = 1/stations{i}.server.serviceProcess{r}{end}.getMean();
                        scv(i,r) = stations{i}.server.serviceProcess{r}{end}.getSCV();
                    end
                end
        end
    end
end

if ~isempty(self.qn)
    self.qn.setService(rates, scv);
end
end
