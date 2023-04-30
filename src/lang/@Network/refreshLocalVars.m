function nvars = refreshLocalVars(self)
% NVARS = REFRESHLOCALVARS()

R = self.getNumberOfClasses;
nvars = zeros(self.getNumberOfNodes, 2*R+1);
nodeparam = cell(self.getNumberOfNodes, 1);
rtnodes = self.sn.rtnodes;
% Draft SPN code:
% isp = [];
% ist = [];
% nodeToPlace = zeros(1, self.getNumberOfNodes);
% nodeToTransition = zeros(1, self.getNumberOfNodes);
% for ind=1:self.getNumberOfNodes
%     node = self.getNodeByIndex(ind);
%     switch class(node)
%     case 'Place'
%         isp = [isp, ind];
%         nodeToPlace(ind) = length(isp);
%     case 'Transition'
%         ist = [ist, ind];
%         nodeToTransition(ind) = length(ist);
%     end
% end
sn = self.sn;

for ind=1:self.getNumberOfNodes
    node = self.getNodeByIndex(ind);
    switch class(node)
        case 'Cache'
            nvars(ind,2*R+1) = sum(node.itemLevelCap);
            nodeparam{ind} = struct();
            nodeparam{ind}.nitems = 0;
            nodeparam{ind}.accost = node.accessProb;
            for r=1:self.getNumberOfClasses
                if ~node.popularity{r}.isDisabled
                    nodeparam{ind}.nitems = max(nodeparam{ind}.nitems,node.popularity{r}.support(2));
                end
            end
            nodeparam{ind}.itemcap = node.itemLevelCap;
            nodeparam{ind}.pread = cell(1,self.getNumberOfClasses);
            for r=1:self.getNumberOfClasses
                if node.popularity{r}.isDisabled
                    nodeparam{ind}.pread{r} = NaN;
                else
                    nodeparam{ind}.pread{r} = node.popularity{r}.evalPMF(1:nodeparam{ind}.nitems);
                end
            end
            nodeparam{ind}.replacement = node.replacementPolicy;
            nodeparam{ind}.hitclass = round(node.server.hitClass);
            nodeparam{ind}.missclass = round(node.server.missClass);
        case 'Fork'
            nodeparam{ind}.fanOut = node.output.tasksPerLink;
        case 'Join'
            nodeparam{ind}.joinStrategy = node.input.joinStrategy;
            nodeparam{ind}.fanIn = cell(1,self.getNumberOfClasses);
            for r=1:self.getNumberOfClasses
                nodeparam{ind}.fanIn{r} = node.input.joinRequired{r};
            end
        case 'Logger'
            nodeparam{ind}.fileName = node.fileName;
            nodeparam{ind}.filePath = node.filePath;
            nodeparam{ind}.startTime = node.getStartTime;
            nodeparam{ind}.loggerName = node.getLoggerName;
            nodeparam{ind}.timestamp = node.getTimestamp;
            nodeparam{ind}.jobID = node.getJobID;
            nodeparam{ind}.jobClass = node.getJobClass;
            nodeparam{ind}.timeSameClass = node.getTimeSameClass;
            nodeparam{ind}.timeAnyClass = node.getTimeAnyClass;
            % Draft SPN code:
            %         case 'Transition'
            %             varsparam{ind} = struct();
            %             varsparam{ind}.modenames = node.modeNames;
            %             nmodes = length(node.modeNames);
            %             inputs = rtnodes(isp, ind);
            %             outputs = rtnodes(ind, isp)';
            %             forw = zeros(length(outputs),nmodes);
            %             back = zeros(length(inputs),nmodes);
            %             inh = zeros(length(inputs),nmodes);
            %             for m=1:nmodes
            %                 for inp=1:length(inputs)
            %                     if inputs(inp) > 0
            %                         back(inp,m) = node.enablingConditions(isp(inp),1,m);
            %                     end
            %                     inh(inp,m) = node.inhibitingConditions(isp(inp),1,m);
            %                 end
            %                 for out=1:length(outputs)
            %                     if outputs(out) > 0
            %                         forw(out,m) = node.firingOutcomes(isp(out),1,m);
            %                     end
            %                 end
            %             end
            %
            %             varsparam{ind}.back = back;
            %             varsparam{ind}.inh = inh;
            %             varsparam{ind}.forw = forw;
            %             varsparam{ind}.nmodes = nmodes;
            %
            %             varsparam{ind}.enablingconditions = node.enablingConditions;
            %             varsparam{ind}.inhibitingconditions = node.inhibitingConditions;
            %
            %             varsparam{ind}.numbersofservers = node.numbersOfServers;
            %             varsparam{ind}.timingstrategies = node.timingStrategies;
            %             varsparam{ind}.distributions = node.distributions;
            %             varsparam{ind}.firingpriorities = node.firingPriorities;
            %             varsparam{ind}.firingweights = node.firingWeights;
            %             varsparam{ind}.firingoutcomes = node.firingOutcomes;
            %             varsparam{ind}.nodeToTransition = nodeToTransition(ind);
            %
            %             [map, mu, phi] = node.getMarkovianServiceRates();
            %
            %             varsparam{ind}.map = map;
            %             varsparam{ind}.mu = mu;
            %             varsparam{ind}.phi = phi;
            %         case 'Place'
            %             varsparam{ind}.nodeToPlace = nodeToPlace(ind);
            %             varsparam{ind}.capacityc = node.classCap;
        case {'Queue','QueueingStation','Delay','DelayStation','Transition'}
            for r=1:self.getNumberOfClasses
                switch class(node.server.serviceProcess{r}{3})
                    case 'MAP'
                        nvars(ind,r) = nvars(ind,r) + 1;
                    case 'Replayer'
                        if isempty(nodeparam{ind})
                            nodeparam{ind} = cell(1,self.getNumberOfClasses);
                        end
                        nodeparam{ind}{r} = struct();
                        nodeparam{ind}{r}.(node.server.serviceProcess{r}{3}.params{1}.paramName) = node.server.serviceProcess{r}{3}.params{1}.paramValue;
                end
            end
    end

    for r=1:R
        switch sn.routing(ind,r)
            case RoutingStrategy.ID_KCHOICES
                nodeparam{ind}{r}.k = node.output.outputStrategy{r}{3}{1};
                nodeparam{ind}{r}.withMemory = node.output.outputStrategy{r}{3}{2};
            case RoutingStrategy.ID_WRROBIN
                nvars(ind,R+r) = nvars(ind,R+r) + 1;
                % save indexes of outgoing links
                if isempty(nodeparam) || isempty(nodeparam{ind}) % reinstantiate if not a cache
                    nodeparam{ind}{r} = struct();
                end
                nodeparam{ind}{r}.weights = zeros(1,self.sn.nnodes);
                nodeparam{ind}{r}.outlinks = find(self.sn.connmatrix(ind,:));
                for c=1:size(node.output.outputStrategy{1, r}{3},2)
                    destination = node.output.outputStrategy{1, r}{3}{c}{1};
                    weight = node.output.outputStrategy{1, r}{3}{c}{2};
                    nodeparam{ind}{r}.weights(destination.index) = weight;
                end
            case RoutingStrategy.ID_RROBIN
                nvars(ind,R+r) = nvars(ind,R+r) + 1;
                % save indexes of outgoing links
                if isempty(nodeparam) || isempty(nodeparam{ind}) % reinstantiate if not a cache
                    nodeparam{ind}{r} = struct();
                end
                nodeparam{ind}{r}.outlinks = find(self.sn.connmatrix(ind,:));
        end
    end
end

if ~isempty(self.sn) %&& isprop(self.sn,'nvars')
    self.sn.nvars = nvars;
    self.sn.nodeparam = nodeparam;
end
end
