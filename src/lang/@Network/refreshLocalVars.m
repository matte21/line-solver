function nvars = refreshLocalVars(self)
% NVARS = REFRESHLOCALVARS()

R = self.getNumberOfClasses;
nvars = zeros(self.getNumberOfNodes, 2*R+1);
varsparam = cell(self.getNumberOfNodes, 1);
rtnodes = self.sn.rtnodes;
sn = self.sn;

for ind=1:self.getNumberOfNodes
    node = self.getNodeByIndex(ind);
    switch class(node)
        case 'Cache'
            nvars(ind,2*R+1) = sum(node.itemLevelCap);
            varsparam{ind} = struct();
            varsparam{ind}.nitems = 0;
            varsparam{ind}.accost = node.accessProb;
            for r=1:self.getNumberOfClasses
                if ~node.popularity{r}.isDisabled
                    varsparam{ind}.nitems = max(varsparam{ind}.nitems,node.popularity{r}.support(2));
                end
            end
            varsparam{ind}.cap = node.itemLevelCap;
            varsparam{ind}.pref = cell(1,self.getNumberOfClasses);
            for r=1:self.getNumberOfClasses
                if node.popularity{r}.isDisabled
                    varsparam{ind}.pref{r} = NaN;
                else
                    varsparam{ind}.pref{r} = node.popularity{r}.evalPMF(1:varsparam{ind}.nitems);
                end
            end
            varsparam{ind}.rpolicy = node.replacementPolicy;
            varsparam{ind}.hitclass = round(node.server.hitClass);
            varsparam{ind}.missclass = round(node.server.missClass);
        case 'Fork'
            varsparam{ind}.fanOut = node.output.tasksPerLink;
        case 'Join'
            varsparam{ind}.joinStrategy = node.input.joinStrategy;
            varsparam{ind}.fanIn = cell(1,self.getNumberOfClasses);
            for r=1:self.getNumberOfClasses
                varsparam{ind}.fanIn{r} = node.input.joinRequired{r};
            end
        case 'Logger'
            varsparam{ind}.fileName = node.fileName;
            varsparam{ind}.filePath = node.filePath;
            varsparam{ind}.startTime = node.getStartTime;
            varsparam{ind}.loggerName = node.getLoggerName;
            varsparam{ind}.timestamp = node.getTimestamp;
            varsparam{ind}.jobID = node.getJobID;
            varsparam{ind}.jobClass = node.getJobClass;
            varsparam{ind}.timeSameClass = node.getTimeSameClass;
            varsparam{ind}.timeAnyClass = node.getTimeAnyClass;
        case {'Queue','QueueingStation','Delay','DelayStation','Transition'}
            for r=1:self.getNumberOfClasses
                switch class(node.server.serviceProcess{r}{3})
                    case 'MAP'
                        nvars(ind,r) = nvars(ind,r) + 1;
                    case 'Replayer'
                        if isempty(varsparam{ind})
                            varsparam{ind} = cell(1,self.getNumberOfClasses);
                        end
                        varsparam{ind}{r} = struct();
                        varsparam{ind}{r}.(node.server.serviceProcess{r}{3}.params{1}.paramName) = node.server.serviceProcess{r}{3}.params{1}.paramValue;
                end
            end
    end

    for r=1:R
        switch sn.routing(ind,r)
            case RoutingStrategy.ID_KCHOICES
                varsparam{ind}{r}.k = node.output.outputStrategy{r}{3}{1};
                varsparam{ind}{r}.withMemory = node.output.outputStrategy{r}{3}{2};
            case RoutingStrategy.ID_WRROBIN
                nvars(ind,R+r) = nvars(ind,R+r) + 1;
                % save indexes of outgoing links
                if isempty(varsparam) || isempty(varsparam{ind}) % reinstantiate if not a cache
                    varsparam{ind}{r} = struct();
                end
                varsparam{ind}{r}.weights = zeros(1,self.sn.nnodes);
                varsparam{ind}{r}.outlinks = find(self.sn.connmatrix(ind,:));
                for c=1:size(node.output.outputStrategy{1, r}{3},2)
                    destination = node.output.outputStrategy{1, r}{3}{c}{1};
                    weight = node.output.outputStrategy{1, r}{3}{c}{2};
                    varsparam{ind}{r}.weights(destination.index) = weight;
                end
            case RoutingStrategy.ID_RROBIN
                nvars(ind,R+r) = nvars(ind,R+r) + 1;
                % save indexes of outgoing links
                if isempty(varsparam) || isempty(varsparam{ind}) % reinstantiate if not a cache
                    varsparam{ind}{r} = struct();
                end
                varsparam{ind}{r}.outlinks = find(self.sn.connmatrix(ind,:));
        end
    end
end

if ~isempty(self.sn) %&& isprop(self.sn,'nvars')
    self.sn.nvars = nvars;
    self.sn.varsparam = varsparam;
end
end
