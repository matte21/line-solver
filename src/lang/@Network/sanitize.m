function sanitize(self)
% SANITIZE()

% Preprocess model to ensure consistent parameterization.
%
% Copyright (c) 2012-2022, Imperial College London
% All rights reserved.

if isempty(self.sn)
    M = getNumberOfStations(self);
    K = getNumberOfClasses(self);
    for i=1:self.getNumberOfNodes
        switch class(self.nodes{i})
            case {'Cache'}
                for k=1:K
                    if k > length(self.nodes{i}.popularity) || isempty(self.nodes{i}.popularity{k})
                        self.nodes{i}.popularity{k} = Disabled.getInstance();
                    end
                end
                if isempty(self.nodes{i}.accessProb)
                    self.nodes{i}.accessProb = cell(K,self.nodes{i}.items.nitems);
                    for v=1:K
                        for k=1:self.nodes{i}.items.nitems
                            % accessProb{v,k}(l,p) is the cost (probability) for a user-v request to item k in list l to access list p
                            self.nodes{i}.accessProb{v,k} = diag(ones(1,self.nodes{i}.nLevels),1);
                            self.nodes{i}.accessProb{v,k}(1+self.nodes{i}.nLevels,1+self.nodes{i}.nLevels) = 1;
                        end
                    end
                end
                self.nodes{i}.server.hitClass = round(self.nodes{i}.server.hitClass);
                self.nodes{i}.server.missClass = round(self.nodes{i}.server.missClass);
            case 'Logger'
                %no-op
            case 'ClassSwitch'
                %no-op
            case 'Join'
                for k=1:K
                    self.nodes{i}.classCap(k) = Inf;
                end
            case 'Queue'
                for k=1:K
                    if k > length(self.nodes{i}.server.serviceProcess) || isempty(self.nodes{i}.server.serviceProcess{k})
                        self.nodes{i}.serviceProcess{k} = Disabled.getInstance();
                        self.nodes{i}.classCap(k) = 0;
                        self.nodes{i}.schedStrategyPar(k) = 0;
                        self.nodes{i}.server.serviceProcess{k} = {[],ServiceStrategy.LI,Disabled.getInstance()};
                        self.nodes{i}.input.inputJobClasses{k} = {[],SchedStrategyType.NP,DropStrategy.WaitingQueue};
                    end
                end
                switch SchedStrategy.toId(self.nodes{i}.schedStrategy)
                    case SchedStrategy.ID_SEPT
                        svcTime = zeros(1,K);
                        for k=1:K
                            svcTime(k) = self.nodes{i}.serviceProcess{k}.getMean;
                        end
                        if length(unique(svcTime)) ~= K
                            line_error(mfilename,'SEPT does not support identical service time means.');
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
                    case SchedStrategy.ID_LEPT
                        svcTime = zeros(1,K);
                        for k=1:K
                            svcTime(k) = self.nodes{i}.serviceProcess{k}.getMean;
                        end
                        if length(unique(svcTime)) ~= K
                            line_error(mfilename,'LEPT does not support identical service time means.');
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
                        self.nodes{i}.serviceProcess{k} = Disabled.getInstance();
                        self.nodes{i}.classCap(k) = 0;
                        self.nodes{i}.schedStrategyPar(k) = 0;
                        self.nodes{i}.server.serviceProcess{k} = {[],ServiceStrategy.LI,Disabled.getInstance()};
                        self.nodes{i}.input.inputJobClasses{k} = {[],SchedStrategyType.NP,DropStrategy.WaitingQueue};
                    end
                end
                switch SchedStrategy.toId(self.nodes{i}.schedStrategy)
                    case SchedStrategy.ID_SEPT
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
                        self.nodes{i}.input.sourceClasses{k} = {[],ServiceStrategy.LI,Disabled.getInstance()};
                    end
                end
            case 'Place'
                for k=1:K
                    if k > length(self.nodes{i}.server.serviceProcess) || isempty(self.nodes{i}.server.serviceProcess{k})
                        self.nodes{i}.schedStrategyPar(k) = 0;
                        self.nodes{i}.server.serviceProcess{k} = {[],ServiceStrategy.LI,Disabled.getInstance()};
                    end
                end
            case 'Transition'
                for k=1:K
                    if k > length(self.nodes{i}.server.serviceProcess) || isempty(self.nodes{i}.server.serviceProcess{k})
                        %                         self.nodes{i}.schedStrategyPar(k) = 0;
                        self.nodes{i}.server.serviceProcess{k} = {[],ServiceStrategy.LI,Disabled.getInstance()};
                    end
                end
        end
    end
    for i=1:M        
        if isempty(self.getIndexSourceStation) || i ~= self.getIndexSourceStation
            for r=1:K
                switch self.stations{i}.server.className
                    case 'ServiceTunnel'
                        % do nothing
                    case 'Cache'
                        self.stations{i}.setProbRouting(self.classes{r}, self.stations{i}, 0.0);
                    otherwise
                        if isempty(self.stations{i}.server.serviceProcess{r})
                            self.stations{i}.server.serviceProcess{r} = {[],ServiceStrategy.LI,Disabled.getInstance()};
                        end
                end
            end
        end
    end
end
end
