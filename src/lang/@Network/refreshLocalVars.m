function nvars = refreshLocalVars(self)
% NVARS = REFRESHLOCALVARS()

nvars = zeros(self.getNumberOfNodes, 1);
varsparam = cell(self.getNumberOfNodes, 1);
rtnodes = self.sn.rtnodes;

for ind=1:self.getNumberOfNodes
    node = self.getNodeByIndex(ind);
    switch class(node)
        case 'Cache'
            nvars(ind) = sum(node.itemLevelCap);
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
            varsparam{ind}.tasksPerLink = node.output.tasksPerLink;
        case 'Join'
            varsparam{ind}.joinStrategy = node.input.joinStrategy;
            varsparam{ind}.joinRequired = cell(1,self.getNumberOfClasses);
            for r=1:self.getNumberOfClasses
                varsparam{ind}.joinRequired{r} = node.input.joinRequired{r};
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
    end
    
    for r=1:self.getNumberOfClasses
        if isprop(node,'serviceProcess')
            switch class(node.server.serviceProcess{r}{3})
                case 'Replayer'
                    if isempty(varsparam{ind})
                        varsparam{ind} = cell(1,self.getNumberOfClasses);
                    end
                    varsparam{ind}{r} = struct();
                    varsparam{ind}{r}.(node.server.serviceProcess{r}{3}.params{1}.paramName) = node.server.serviceProcess{r}{3}.params{1}.paramValue;
            end
        end
    end
    switch self.sn.routing(ind)
        case RoutingStrategy.ID_RROBIN
            nvars(ind) = nvars(ind) + 1;
            % save indexes of outgoing links
            if isempty(varsparam) % reinstantiate if not a cache
                varsparam{ind} = struct();
            end
            varsparam{ind}.outlinks = find(sum(reshape(rtnodes(ind,:)>0,self.sn.nnodes,self.sn.nclasses),2)');
    end
end

if ~isempty(self.sn) %&& isprop(self.sn,'nvars')
    self.sn.nvars = nvars;
    self.sn.varsparam = varsparam;
end
end
