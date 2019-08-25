function sanitize(self)
% SANITIZE()

% Preprocess model to ensure consistent parameterization.
%
% Copyright (c) 2012-2019, Imperial College London
% All rights reserved.

if isempty(self.qn)
    M = self.getNumberOfStations();
    K = self.getNumberOfClasses();
    for i=1:self.getNumberOfNodes
        switch class(self.nodes{i})
            case {'Cache'}
                for k=1:K
                    if k > length(self.nodes{i}.popularity) || isempty(self.nodes{i}.popularity{k})
                        self.nodes{i}.popularity{k} = Disabled();
                    end
                end
                if isempty(self.nodes{i}.accessCost)
                    self.nodes{i}.accessCost = cell(K,self.nodes{i}.items.nitems);
                    for v=1:K
                        for j=1:self.nodes{i}.items.nitems
                            self.nodes{i}.accessCost{v,j} = diag(ones(1,self.nodes{i}.nLevels-1),1);
                        end
                    end
                end
            case 'Logger'
                %no-op
            case 'ClassSwitch'
                %no-op
            case 'Queue'
                for k=1:K
                    if k > length(self.nodes{i}.server.serviceProcess) || isempty(self.nodes{i}.server.serviceProcess{k})
                        self.nodes{i}.serviceProcess{k} = Disabled();
                        self.nodes{i}.classCap(k) = 0;
                        self.nodes{i}.schedStrategyPar(k) = 0;
                        self.nodes{i}.server.serviceProcess{k} = {[],ServiceStrategy.LI,Disabled()};
                    end
                end
                switch self.nodes{i}.schedStrategy
                    case SchedStrategy.SEPT
                        svcTime = zeros(1,K);
                        for k=1:K
                            svcTime(k) = self.nodes{i}.serviceProcess{k}.getMean;
                        end
                        if length(unique(svcTime)) ~= K
                            error('SEPT does not support identical service time means.');
                        end
                        [svcTimeSorted] = sort(unique(svcTime));
                        self.nodes{i}.schedStrategyPar = zeros(1,K);
                        for k=1:K
                            if ~isnan(svcTime(k))
                                self.nodes{i}.schedStrategyPar(k) = find(svcTimeSorted == svcTime(k));
                            else
                                self.nodes{i}.schedStrategyPar(k) = find(isnan(svcTimeSorted));
                            end
                        end
                    case SchedStrategy.LEPT
                        svcTime = zeros(1,K);
                        for k=1:K
                            svcTime(k) = self.nodes{i}.serviceProcess{k}.getMean;
                        end
                        if length(unique(svcTime)) ~= K
                            error('LEPT does not support identical service time means.');
                        end                        
                        [svcTimeSorted] = sort(unique(svcTime),'descend');
                        self.nodes{i}.schedStrategyPar = zeros(1,K);
                        for k=1:K
                            self.nodes{i}.schedStrategyPar(k) = find(svcTimeSorted == svcTime(k));
                        end
                end
            case 'Delay'
                for k=1:K
                    if k > length(self.nodes{i}.server.serviceProcess) || isempty(self.nodes{i}.server.serviceProcess{k})
                        self.nodes{i}.serviceProcess{k} = Disabled();
                        self.nodes{i}.classCap(k) = 0;
                        self.nodes{i}.schedStrategyPar(k) = 0;
                        self.nodes{i}.server.serviceProcess{k} = {[],ServiceStrategy.LI,Disabled()};
                    end
                end
                switch self.nodes{i}.schedStrategy
                    case SchedStrategy.SEPT
                        svcTime = zeros(1,K);
                        for k=1:K
                            svcTime(k) = self.nodes{i}.serviceProcess{k}.getMean;
                        end
                        [~,self.nodes{i}.schedStrategyPar] = sort(svcTime);
                end
            case 'Sink'
                % no-op
            case 'Source'
                for k=1:K
                    if k > length(self.nodes{i}.input.sourceClasses) || isempty(self.nodes{i}.input.sourceClasses{k})
                        self.nodes{i}.input.sourceClasses{k} = {[],ServiceStrategy.LI,Disabled()};
                    end
                end
        end
    end
    for i=1:M
        for r=1:K
            if isempty(self.getIndexSourceStation) || i ~= self.getIndexSourceStation
                switch self.stations{i}.server.className
                    case 'ServiceTunnel'
                        % do nothing
                    case 'Cache'
                        self.stations{i}.setProbRouting(self.classes{r}, self.stations{i}, 0.0);
                    otherwise
                        if isempty(self.stations{i}.server.serviceProcess{r})
                            self.stations{i}.server.serviceProcess{r} = {[],ServiceStrategy.LI,Disabled()};
                        end
                end
            end
        end
    end
end
end
