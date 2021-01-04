classdef Network < Model
    % An extended queueing network model.
    %
    % Copyright (c) 2012-2021, Imperial College London
    % All rights reserved.
    
    properties (Access=private)
        usedFeatures; % structure of booleans listing the used classes
        % it must be accessed via getUsedLangFeatures that updates
        % the Distribution classes dynamically
        logPath;
        linkedRoutingTable;
        isInitialized;
        doChecks;
    end
    
    properties (Access=protected)
        items;
        qn;
    end
    
    properties (Hidden)
        handles;
        perfIndex;        
        stationidxs;
        sourceidx;
        sinkidx;
    end
    
    properties
        classes;
        stations;
        nodes;
        connections;
    end
    
    methods % public methods in class folder
        
        sa = getStruct(self, structType, wantState) % get abritrary representation
        
        used = getUsedLangFeatures(self) % get used features
        
        ft = getForks(self, rt) % get fork table
        [chainsObj,chainsMatrix] = getChains(self, rt) % get chain table
        
        [rt,rtNodes,connections,rtNodesByClass,rtNodesByStation] = getRoutingMatrix(self, arvRates) % get routing matrix
        
        nodes = resetNetwork(self)
        
        self = link(self, P)
        [loggerBefore,loggerAfter] = linkAndLog(self, nodes, classes, P, wantLogger, logPath)        
        
        function [loggerBefore,loggerAfter] = linkNetworkAndLog(self, nodes, classes, P, wantLogger, logPath)% obsolete - old name
            % [LOGGERBEFORE,LOGGERAFTER] = LINKNETWORKANDLOG(NODES, CLASSES, P, WANTLOGGER, LOGPATH)% OBSOLETE - OLD NAME
            
            [loggerBefore,loggerAfter] = linkAndLog(self, nodes, classes, P, wantLogger, logPath);
        end
        
        [Q,U,R,T,A] = getAvgHandles(self)
        A = getAvgArvRHandles(self);
        T = getAvgTputHandles(self);
        Q = getAvgQLenHandles(self);
        R = getAvgRespTHandles(self);
        U = getAvgUtilHandles(self);
        [Qt,Ut,Tt] = getTranHandles(self)
        connections = getConnectionMatrix(self);
        sanitize(self);
    end
    
    methods %refresh methods
        function resetPerfIndexes(self)
            self.perfIndex.Avg = {};
            self.perfIndex.Tran = {};
        end
        
        function resetHandles(self)
            self.handles = {};
            resetPerfIndexes(self);
        end
        
        function reset(self, resetState)
            % RESET(RESETSTATE)
            %
            % If RESETSTATE is true, the model requires re-initialization
            % of its state
            if nargin == 1
                resetModel(self);
            else
                resetModel(self, resetState);
            end
        end
        
        function resetStruct(self)
            self.qn = [];
        end
        
        function resetModel(self, resetState)
            % RESETMODEL(RESETSTATE, RESETHANDLES)
            %
            % If RESETSTATE is true, the model requires re-initialization
            % of its state
            
            resetHandles(self);
            self.qn = [];
            
            if nargin == 2 && resetState
                self.isInitialized = false;
            end
            for ind = 1:length(self.getNodes)
                self.nodes{ind}.reset();
            end
            self.stationidxs = [];
        end
        
        self = removeClass(self, jobclass);           
        
        refreshStruct(self);
        [rates, scv, hasRateChanged, hasSCVChanged] = refreshRates(self, statSet, classSet);
        [ph, mu, phi, phases] = refreshServicePhases(self, statSet, classSet);
        proctypes = refreshServiceTypes(self);
        [rt, rtfun, rtnodes] = refreshRoutingMatrix(self, rates);
        [lt] = refreshLST(self, statSet, classSet);
        sync = refreshSync(self);
        classprio = refreshPriorities(self);
        [sched, schedid, schedparam] = refreshScheduling(self);
        function [rates, mu, phi, phases] = refreshArrival(self) % LINE treats arrival distributions as service distributions of the Source object
            % [RATES, MU, PHI, PHASES] = REFRESHARRIVAL() % LINE TREATS ARRIVAL DISTRIBUTIONS AS SERVICE DISTRIBUTIONS OF THE SOURCE OBJECT
            
            [rates, mu, phi, phases, ~, ~] = refreshService(self);
        end
        [rates, scv, mu, phi, phases] = refreshService(self, statSet, classSet);
        [chains, visits, rt] = refreshChains(self, propagate)
        [visits, nodevisits] = refreshVisits(self, chains, rt, rtNodes)
        [cap, classcap] = refreshCapacity(self);
        nvars = refreshLocalVars(self);
    end
    
    % PUBLIC METHODS
    methods (Access=public)
        
        %Constructor
        function self = Network(modelName)
            % SELF = NETWORK(MODELNAME)
            self@Model(modelName);
            self.nodes = {};
            self.stations = {};
            self.classes = {};
            self.connections = [];
            self.perfIndex = struct();
            self.perfIndex.('Avg') = {};
            self.perfIndex.('Tran') = {};
            initUsedFeatures(self);
            self.qn = [];
            self.linkedRoutingTable = {};
            self.isInitialized = false;
            self.logPath = '';
            self.items = {};
            self.stationidxs = [];
            self.sourceidx = [];
            self.sinkidx = [];
            self.setChecks(true);
        end
        
        setInitialized(self, bool);        
        
        function bool = hasStruct(self)
            bool = ~isempty(self.qn);
        end
        
        function self = setChecks(self, bool)
            self.doChecks = bool;
        end
        
        function nodes = getNodes(self)
            % NODES = GETNODES()
            
            nodes = self.nodes;
        end
        
        P = getLinkedRoutingMatrix(self)
        
        function logPath = getLogPath(self)
            % LOGPATH = GETLOGPATH()
            
            logPath = self.logPath;
        end
        
        function setLogPath(self, logPath)
            % SETLOGPATH(LOGPATH)
            
            self.logPath = logPath;
        end
        
        function bool = hasInitState(self)
            % BOOL = HASINITSTATE()
            
            bool = true;
            if ~self.isInitialized % check if all stations are initialized
                for ind=1:self.getNumberOfNodes
                    if isa(self.nodes{ind},'StatefulNode') && isempty(self.nodes{ind}.state)
                        bool = false;
                    end
                end
            end
        end       
        
        function [M,R] = getSize(self)
            % [M,R] = GETSIZE()
            
            M = self.getNumberOfNodes;
            R = self.getNumberOfClasses;
        end
        
        function bool = hasOpenClasses(self)
            % BOOL = HASOPENCLASSES()
            
            bool = any(isinf(getNumberOfJobs(self)));
        end
        
        function bool = hasClassSwitch(self)
            % BOOL = HASCLASSSWITCH()
            
            bool = any(cellfun(@(c) isa(c,'ClassSwitch'), self.nodes));
        end
        
        function bool = hasClosedClasses(self)
            % BOOL = HASCLOSEDCLASSES()
            
            bool = any(isfinite(getNumberOfJobs(self)));
        end
        
        function index = getIndexOpenClasses(self)
            % INDEX = GETINDEXOPENCLASSES()
            
            index = find(isinf(getNumberOfJobs(self)))';
        end
        
        function index = getIndexClosedClasses(self)
            % INDEX = GETINDEXCLOSEDCLASSES()
            
            index = find(isfinite(getNumberOfJobs(self)))';
        end
        
        function c = getClassChain(self, className)
            % C = GETCLASSCHAIN(CLASSNAME)
            
            chains = self.getChains;
            if ischar(className)
                for c = 1:length(chains)
                    if any(cell2mat(strfind(chains{c}.classnames,className)))
                        return
                    end
                end
            else
                for c = 1:length(chains)
                    if any(cell2mat(chains{c}.index==1))
                        return
                    end
                end
            end
            c = -1;
        end
        
        function classNames = getClassNames(self)
            % CLASSNAMES = GETCLASSNAMES()
            if ~isempty(self.qn)
                classNames = self.qn.classnames;
            else
                for r=1:getNumberOfClasses(self)
                    classNames{r,1}=self.classes{r}.name;
                end
            end
        end
        
        function nodeNames = getNodeNames(self)
            % NODENAMES = GETNODENAMES()
            
            % The commented block causes issues with Logger nodes
            % see e.g., getting_started_ex7
            if ~isempty(self.qn)
                nodeNames = self.qn.nodenames;
            else
                M = getNumberOfNodes(self);
                nodeNames = cell(M,1);
                for i=1:M
                    nodeNames{i,1} = self.nodes{i}.name;
                end
            end
        end
        
        function nodeTypes = getNodeTypes(self)
            % NODETYPES = GETNODETYPES()
            
            nodeTypes = zeros(self.getNumberOfNodes,1);
            for i=1:self.getNumberOfNodes
                switch class(self.nodes{i})
                    case 'Cache'
                        nodeTypes(i) = NodeType.Cache;
                    case 'Logger'
                        nodeTypes(i) = NodeType.Logger;
                    case 'ClassSwitch'
                        nodeTypes(i) = NodeType.ClassSwitch;
                    case {'Queue','QueueingStation'}
                        nodeTypes(i) = NodeType.Queue;
                    case 'Sink'
                        nodeTypes(i) = NodeType.Sink;
                    case 'Router'
                        nodeTypes(i) = NodeType.Router;
                    case {'Delay','DelayStation'}
                        nodeTypes(i) = NodeType.Delay;
                    case 'Fork'
                        nodeTypes(i) = NodeType.Fork;
                    case 'Join'
                        nodeTypes(i) = NodeType.Join;
                    case 'Source'
                        nodeTypes(i) = NodeType.Source;
                    case 'Place'
                        nodeTypes(i) = NodeType.Place;
                    case 'Transition'
                        nodeTypes(i) = NodeType.Transition;
                    otherwise
                        line_error(mfilename,'Unknown node type.');
                end
            end
        end
        
        function P = initRoutingMatrix(self)
            % P = INITROUTINGMATRIX()
            
            M = self.getNumberOfNodes;
            K = self.getNumberOfClasses;
            P = cellzeros(K,K,M,M);
        end
        
        function rtTypes = getRoutingStrategies(self)
            % RTTYPES = GETROUTINGSTRATEGIES()
            
            rtTypes = zeros(self.getNumberOfNodes,self.getNumberOfClasses);
            for ind=1:self.getNumberOfNodes
                for r=1:self.getNumberOfClasses
                    switch self.nodes{ind}.output.outputStrategy{r}{2}
                        case RoutingStrategy.RAND
                            rtTypes(ind,r) = RoutingStrategy.ID_RAND;
                        case RoutingStrategy.PROB
                            rtTypes(ind,r) = RoutingStrategy.ID_PROB;
                        case RoutingStrategy.RRB
                            rtTypes(ind,r) = RoutingStrategy.ID_RRB;
                        case RoutingStrategy.JSQ
                            rtTypes(ind,r) = RoutingStrategy.ID_JSQ;
                        case RoutingStrategy.DISABLED
                            rtTypes(ind,r) = RoutingStrategy.ID_DISABLED;
                    end
                end
            end
        end
        
        function ind = getNodeIndex(self, name)
            % NODEINDEX = GETNODEINDEX(NAME)
            
            if isa(name,'Node')
                %node = name;
                %name = node.getName();
                ind = name.index;
                return
            end
            ind = find(cellfun(@(c) strcmp(c,name),self.getNodeNames));
        end
        
        function stationIndex = getStationIndex(self, name)
            % STATIONINDEX = GETSTATIONINDEX(NAME)
            
            if isa(name,'Node')
                node = name;
                name = node.getName();
            end
            stationIndex = find(cellfun(@(c) strcmp(c,name),self.getStationNames));
        end
        
        function statefulIndex = getStatefulNodeIndex(self, name)
            % STATEFULINDEX = GETSTATEFULNODEINDEX(NAME)
            
            if isa(name,'Node')
                node = name;
                name = node.getName();
            end
            statefulIndex = find(cellfun(@(c) strcmp(c,name),self.getStatefulNodeNames));
        end
        
        function classIndex = getClassIndex(self, name)
            % CLASSINDEX = GETCLASSINDEX(NAME)
            if isa(name,'JobClass')
                jobclass = name;
                name = jobclass.getName();
            end
            classIndex = find(cellfun(@(c) strcmp(c,name),self.getClassNames));
        end
        
        function stationnames = getStationNames(self)
            % STATIONNAMES = GETSTATIONNAMES()
            
            if self.hasStruct
                stationnames = {self.qn.nodenames{self.qn.isstation}}';
            else
                stationnames = {};
                for i=self.getIndexStations
                    stationnames{end+1,1} = self.nodes{i}.name;
                end
            end
        end
        
        function nodes = getNodeByName(self, name)
            % NODES = GETNODEBYNAME(SELF, NAME)
            idx = findstring(self.getNodeNames,name);
            if idx > 0
                nodes = self.nodes{idx};
            else
                nodes = NaN;
            end
        end
        
        function station = getStationByName(self, name)
            % STATION = GETSTATIONBYNAME(SELF, NAME)
            idx = findstring(self.getStationNames,name);
            if idx > 0
                station = self.stations{idx};
            else
                station = NaN;
            end
        end
        
        function class = getClassByName(self, name)
            % CLASS = GETCLASSBYNAME(SELF, NAME)
            idx = findstring(self.getClassNames,name);
            if idx > 0
                class = self.classes{idx};
            else
                class = NaN;
            end
        end
        
        function nodes = getNodeByIndex(self, idx)
            % NODES = GETNODEBYINDEX(SELF, NAME)
            if idx > 0
                nodes = self.nodes{idx};
            else
                nodes = NaN;
            end
        end
        
        function station = getStationByIndex(self, idx)
            % STATION = GETSTATIONBYINDEX(SELF, NAME)
            if idx > 0
                station = self.stations{idx};
            else
                station = NaN;
            end
        end
        
        function class = getClassByIndex(self, idx)
            % CLASS = GETCLASSBYINDEX(SELF, NAME)
            if idx > 0
                class = self.classes{idx};
            else
                class = NaN;
            end
        end
                
        function [stateSpace,nodeStateSpace] = getStateSpace(self, varargin)
            line_error(mfilename,'This method is no longer supported. Use SolverCTMC(model,...).getStateSpace(...) instead.');
        end
        
        function summary(self)
            % SUMMARY()
            
            for i=1:self.getNumberOfNodes
                self.nodes{i}.summary();
            end
        end
        
        function [D,Z] = getDemands(self)
            % [D,Z]= GETDEMANDS()            
            
            [~,D,~,Z,~,~] = snGetProductFormParams(self.getStruct); 
        end
        
        function [lambda,D,N,Z,mu,S]= getProductFormParameters(self)
            % [LAMBDA,D,N,Z,MU,S]= GETPRODUCTFORMPARAMETERS()
            
            % mu also returns max(S) elements after population |N| as this is
            % required by MVALDMX
            
            [lambda,D,N,Z,mu,S] = snGetProductFormParams(self.getStruct); 
        end
        
        function statefulnodes = getStatefulNodes(self)
            statefulnodes = {};
            for i=1:self.getNumberOfNodes
                if self.nodes{i}.isStateful
                    statefulnodes{end+1,1} = self.nodes{i};
                end
            end
        end
        
        function statefulnames = getStatefulNodeNames(self)
            % STATEFULNAMES = GETSTATEFULNODENAMES()
            
            statefulnames = {};
            for i=1:self.getNumberOfNodes
                if self.nodes{i}.isStateful
                    statefulnames{end+1,1} = self.nodes{i}.name;
                end
            end
        end
        
        function M = getNumberOfNodes(self)
            % M = GETNUMBEROFNODES()
            
            M = length(self.nodes);
        end
        
        function S = getNumberOfStatefulNodes(self)
            % S = GETNUMBEROFSTATEFULNODES()
            
            S = sum(cellisa(self.nodes,'StatefulNode'));
        end
        
        function M = getNumberOfStations(self)
            % M = GETNUMBEROFSTATIONS()
            
            M = length(self.stations);
        end
        
        function R = getNumberOfClasses(self)
            % R = GETNUMBEROFCLASSES()
            
            R = length(self.classes);
        end
        
        function C = getNumberOfChains(self)
            % C = GETNUMBEROFCHAINS()
            
            qn = self.getStruct;
            C = qn.nchains;
        end
        
        function Dchain = getDemandsChain(self)
            % DCHAIN = GETDEMANDSCHAIN()            
           snGetDemandsChain(self.getStruct);
        end
        
        % setUsedFeatures : records that a certain language feature has been used
        function self = setUsedFeatures(self,className)
            % SELF = SETUSEDFEATURES(SELF,CLASSNAME)
            
            self.usedFeatures.setTrue(className);
        end
        
        %% Add the components to the model
        addJobClass(self, customerClass);
        addNode(self, node);
        addLink(self, nodeA, nodeB);
        addLinks(self, nodeList);
        addItemSet(self, itemSet);                
        addMetric(self, performanceIndex);
        self = disableMetric(self, Y);
        self = enableMetric(self, Y);
        
        node = getSource(self);
        node = getSink(self);
        
        function list = getDummys(self)
            % LIST = GETDUMMYS()
            
            list = find(cellisa(self.nodes, 'Passage'))';
        end
        
        function list = getIndexStations(self)
            % LIST = GETINDEXSTATIONS()
            
            if isempty(self.stationidxs)
                % returns the ids of nodes that are stations
                self.stationidxs = find(cellisa(self.nodes, 'Station'))';
            end
            list = self.stationidxs;
        end
        
        function list = getIndexStatefulNodes(self)
            % LIST = GETINDEXSTATEFULNODES()
            
            % returns the ids of nodes that are stations
            list = find(cellisa(self.nodes, 'StatefulNode'))';
        end
        
        index = getIndexSourceStation(self);
        index = getIndexSourceNode(self);
        index = getIndexSinkNode(self);
        
        N = getNumberOfJobs(self);
        refstat = getReferenceStations(self);
        sched = getStationScheduling(self);
        S = getStationServers(self);
        
        function jsimwView(self)
            % JSIMWVIEW()
            
            [Q,U,R,T,A] = getAvgHandles(self); % create measures
            s=SolverJMT(self,Solver.defaultOptions,jmtGetPath);
            s.jsimwView;
        end
        
        function jsimgView(self)
            % JSIMGVIEW()
            
            [Q,U,R,T,A] = getAvgHandles(self); % create measures
            s=SolverJMT(self,Solver.defaultOptions,jmtGetPath); s.jsimgView;
        end
        
        function [ni, nir, sir, kir] = initToMarginal(self)
            % [NI, NIR, SIR, KIR] = INITTOMARGINAL()
            
            [ni, nir, sir, kir] = snInitToMarginal(self.getStruct);
        end
        
        function [isvalid] = isStateValid(self)
            % [ISVALID] = ISSTATEVALID()
            
            isvalid = snIsStateValid(self.getStruct);
        end
        
        function [initialStateAggr] = getStateAggr(self) % get initial state
            % [INITIALSTATEAGGR] = GETSTATEAGGR() % GET INITIAL STATE
            
            initialStateAggr = snGetStateAggr(self.getStruct);
        end
        
        function [initialState, priorInitialState] = getState(self) % get initial state
            % [INITIALSTATE, PRIORINITIALSTATE] = GETSTATE() % GET INITIAL STATE
            
            if ~self.hasInitState
                self.initDefault;
            end
            initialState = {};
            priorInitialState = {};
            for ind=1:length(self.nodes)
                if self.nodes{ind}.isStateful
                    initialState{end+1,1} = self.nodes{ind}.getState();
                    priorInitialState{end+1,1} = self.nodes{ind}.getStatePrior();
                end
            end
        end
        
        function initFromAvgTableQLen(self, AvgTable)
            QN = reshape(AvgTable.QLen,self.getNumberOfClasses,self.getNumberOfStations)';
            self.initFromAvgQLen(QN);
        end
        
        function initFromAvgQLen(self, AvgQLen)
            % INITFROMAVGQLEN(AVGQLEN)
            n = round(AvgQLen);
            njobs = sum(n,1);
            % we now address the problem that round([0.5,0.5]) = [1,1] so
            % different from the total initial population
            for r=1:size(AvgQLen,2)
                if njobs(r) > sum(AvgQLen,1) % error at most by 1
                    i = maxpos(n(:,r));
                    n(i,r) = n(i,r) - 1;
                    njobs = sum(n,1)';
                end
            end
            try
                self.initFromMarginal(n);
            catch
                self.initDefault;
            end
        end
        
        function initDefault(self, nodes)
            % INITDEFAULT(NODES)
            
            % open classes empty
            % closed classes initialized at ref station
            % running jobs are allocated in class id order until all
            % servers are busy
            
            %refreshStruct(self);  % we force update of the model before we initialize
            
            qn = self.getStruct(false);
            N = qn.njobs';
            if nargin < 2
                nodes = 1:self.getNumberOfNodes;
            end
            
            for i=nodes
                if qn.isstation(i)
                    n0 = zeros(1,length(N));
                    s0 = zeros(1,length(N));
                    s = qn.nservers(qn.nodeToStation(i)); % allocate
                    for r=find(isfinite(N))' % for all closed classes
                        if qn.nodeToStation(i) == qn.refstat(r)
                            n0(r) = N(r);
                        end
                        s0(r) = min(n0(r),s);
                        s = s - s0(r);
                    end
                    state_i = State.fromMarginalAndStarted(qn,i,n0(:)',s0(:)');
                    switch qn.nodetype(i)
                        case NodeType.Cache
                            state_i = [state_i, 1:qn.nvars(i)];
                        case NodeType.Place
                            state_i = 0; % for now PNs are single class
                    end
                    switch qn.routing(i)
                        case RoutingStrategy.ID_RRB
                            % start from first connected queue
                            state_i = [state_i, find(qn.rt(i,:),1)];
                    end
                    if isempty(state_i)
                        line_error(mfilename,sprintf('Default initialization failed on station %d.',i));
                    else
                        %state_i = state_i(1,:); % to change: this effectively disables priors
                        self.nodes{i}.setState(state_i);
                        prior_state_i = zeros(1,size(state_i,1)); prior_state_i(1) = 1;
                        self.nodes{i}.setStatePrior(prior_state_i);
                    end
                elseif qn.isstateful(i) % not a station
                    switch class(self.nodes{i})
                        case 'Cache'
                            state_i = zeros(1,self.getNumberOfClasses);
                            state_i = [state_i, 1:sum(self.nodes{i}.itemLevelCap)];
                            self.nodes{i}.setState(state_i);
                        case 'Router'
                            self.nodes{i}.setState([1]);
                        otherwise
                            self.nodes{i}.setState([]);
                    end
                    %line_error(mfilename,'Default initialization not available on stateful node %d.',i);
                end
            end
            
            if self.isStateValid % problem with example_initState_2
                self.isInitialized = true;
            else
                line_error(mfilename,'Default initialization failed.');
            end
        end
        
        function initFromMarginal(self, n, options) % n(i,r) : number of jobs of class r in node i
            % INITFROMMARGINAL(N, OPTIONS) % N(I,R) : NUMBER OF JOBS OF CLASS R IN NODE I
            
            qn = getStruct(self);
            if nargin<3 %~exist('options','var')
                options = Solver.defaultOptions;
            end
            [isvalidn] = State.isValid(qn, n, [], options);
            if ~isvalidn
                %         line_error(mfilename,'The specified state does not have the correct number of jobs.');
                line_warning(mfilename,'Initial state not contained in the state space. Trying to recover.');
                n = round(n);
                [isvalidn] = State.isValid(qn, n, [], options);
                if ~isvalidn
                    line_error(mfilename,'Cannot recover - stopping.');
                end
            end
            for ind=1:qn.nnodes
                if qn.isstateful(ind)
                    ist = qn.nodeToStation(ind);
                    switch qn.nodetype(ind)
                        case NodeType.Place
                            self.nodes{ind}.setState(sum(n(ist,:))); % must be single class token
                        otherwise
                            self.nodes{ind}.setState(State.fromMarginal(qn,ind,n(ist,:)));
                    end
                    if isempty(self.nodes{ind}.getState)
                        line_error(sprintf('Invalid state assignment for station %d.',ind));
                    end
                end
            end
            self.isInitialized = true;
        end
        
        function initFromMarginalAndRunning(self, n, s, options) % n(i,r) : number of jobs of class r in node i
            % INITFROMMARGINALANDRUNNING(N, S, OPTIONS) % N(I,R) : NUMBER OF JOBS OF CLASS R IN NODE I
            
            qn = getStruct(self);
            [isvalidn] = State.isValid(qn, n, s);
            if ~isvalidn
                line_error(mfilename,'Initial state is not valid.');
            end
            for i=1:self.getNumberOfNodes
                if self.nodes{i}.isStateful
                    self.nodes{i}.setState(State.fromMarginalAndRunning(qn,i,n(i,:),s(i,:)));
                    if isempty(self.nodes{i}.getState)
                        line_error(sprintf('Invalid state assignment for station %d\n',i));
                    end
                end
            end
            self.isInitialized = true;
        end
        
        function initFromMarginalAndStarted(self, n, s, options) % n(i,r) : number of jobs of class r in node i
            % INITFROMMARGINALANDSTARTED(N, S, OPTIONS) % N(I,R) : NUMBER OF JOBS OF CLASS R IN NODE I
            
            qn = getStruct(self);
            [isvalidn] = State.isValid(qn, n, s);
            if ~isvalidn
                line_error(mfilename,'Initial state is not valid.');
            end
            for ind=1:self.getNumberOfNodes
                if self.nodes{ind}.isStateful
                    ist = qn.nodeToStation(ind);
                    self.nodes{ind}.setState(State.fromMarginalAndStarted(qn,ind,n(ist,:),s(ist,:)));
                    if isempty(self.nodes{ind}.getState)
                        line_error(sprintf('Invalid state assignment for station %d\n',ind));
                    end
                end
            end
            self.isInitialized = true;
        end
        
        function [H,G] = getGraph(self)
            % [H,G] = GETGRAPH()
            
            G = digraph(); TG = Table();
            M = self.getNumberOfNodes;
            K = self.getNumberOfClasses;
            qn = self.getStruct;
            [P,Pnodes] = getRoutingMatrix(self);
            name = {}; sched = {}; type = {}; nservers = [];
            for i=1:M
                name{end+1} = self.nodes{i}.name;
                type{end+1} = class(self.nodes{i});
                sched{end+1} = self.nodes{i}.schedStrategy;
                if isa(self.nodes{i},'Station')
                    nservers(end+1) = self.nodes{i}.getNumberOfServers;
                else
                    nservers(end+1) = 0;
                end
            end
            TG.Name = name(:);
            TG.Type = type(:);
            TG.Sched = sched(:);
            TG.Servers = nservers(:);
            G = G.addnode(TG);
            for i=1:M
                for j=1:M
                    for k=1:K
                        if Pnodes((i-1)*K+k,(j-1)*K+k) > 0
                            G = G.addedge(self.nodes{i}.name,self.nodes{j}.name, Pnodes((i-1)*K+k,(j-1)*K+k));
                        end
                    end
                end
            end
            H = digraph(); TH = Table();
            I = self.getNumberOfStations;
            name = {}; sched = {}; type = {}; jobs = zeros(I,1); nservers = [];
            for i=1:I
                name{end+1} = self.stations{i}.name;
                type{end+1} = class(self.stations{i});
                sched{end+1} = self.stations{i}.schedStrategy;
                for k=1:K
                    if qn.refstat(k)==i
                        jobs(i) = jobs(i) + qn.njobs(k);
                    end
                end
                if isa(self.nodes{i},'Station')
                    nservers(end+1) = self.nodes{i}.getNumberOfServers;
                else
                    nservers(end+1) = 0;
                end
            end
            TH.Name = name(:);
            TH.Type = type(:);
            TH.Sched = sched(:);
            TH.Jobs = jobs(:);
            TH.Servers = nservers(:);
            H = H.addnode(TH);
            rate = [];
            classes = {};
            for i=1:I
                for j=1:I
                    for k=1:K
                        if P((i-1)*K+k,(j-1)*K+k) > 0
                            rate(end+1) = qn.rates(i,k);
                            classes{end+1} = self.classes{k}.name;
                            H = H.addedge(self.stations{i}.name, self.stations{j}.name, P((i-1)*K+k,(j-1)*K+k));
                        end
                    end
                end
            end
            H.Edges.Rate = rate(:);
            H.Edges.Class = classes(:);
            H = H.rmedge(find(isnan(H.Edges.Rate)));
            sourceObj = self.getSource;
            if ~isempty(sourceObj)
                %                 sink = self.getSink;
                %                 H=H.addnode(sink.name);
                %                 H.Nodes.Type{end}='Sink';
                %                 H.Nodes.Sched{end}='ext';
                %H = H.rmedge(find(isnan(H.Edges.Rate)));
                %sourceIdx = model.getIndexSourceNode;
                %                toDel = findstring(H.Edges.EndNodes(:,2),sourceObj.name);
                %                for j=toDel(:)'
                %                    H = H.rmedge(j);
                %                end
            end
        end
        
        function mask = getClassSwitchingMask(self)
            % MASK = GETCLASSSWITCHINGMASK()
            
            mask = self.getStruct.csmask;
        end
        
        function printRoutingMatrix(self)
            % PRINTROUTINGMATRIX()
            
            snPrintRoutingMatrix(self.getStruct);
        end                        
    end
    
    % Private methods
    methods (Access = 'private')
        
        function out = getModelNameExtension(self)
            % OUT = GETMODELNAMEEXTENSION()
            
            out = [getModelName(self), ['.', self.fileFormat]];
        end
        
        function self = initUsedFeatures(self)
            % SELF = INITUSEDFEATURES()
            
            % The list includes all classes but Model and Hidden or
            % Constant or Abstract or Solvers
            self.usedFeatures = SolverFeatureSet;
        end
    end
    
    methods(Access = protected)
        % Override copyElement method:
        function clone = copyElement(self)
            % CLONE = COPYELEMENT()
            
            % Make a shallow copy of all properties
            clone = copyElement@Copyable(self);
            % Make a deep copy of each handle
            for i=1:length(self.classes)
                clone.classes{i} = self.classes{i}.copy;
            end
            % Make a deep copy of each handle
            for i=1:length(self.nodes)
                clone.nodes{i} = self.nodes{i}.copy;
                if isa(clone.nodes{i},'Station')
                    clone.stations{i} = clone.nodes{i};
                end
                clone.connections = self.connections;
            end
            
            % Metric objects do not contain object handles
            for i=1:length(self.perfIndex.Avg)
                clone.perfIndex.Avg{i} = self.perfIndex.Avg{i}.copy;
            end
            for i=1:length(self.perfIndex.Tran)
                clone.perfIndex.Tran{i} = self.perfIndex.Tran{i}.copy;
            end
        end
    end
    
    methods
        function bool = hasFCFS(self)
            % BOOL = HASFCFS()
            
            bool = snHasFCFS(self.getStruct);
        end
        
        function bool = hasHomogeneousScheduling(self, strategy)
            % BOOL = HASHOMOGENEOUSSCHEDULING(STRATEGY)
            
            bool = snHasHomogeneousScheduling(self.getStruct, strategy);
        end
        
        function bool = hasDPS(self)
            % BOOL = HASDPS()
            
            bool = snHasDPS(self.getStruct);
        end
        
        function bool = hasGPS(self)
            % BOOL = HASGPS()
            
            bool = snHasGPS(self.getStruct);
        end
        
        function bool = hasINF(self)
            % BOOL = HASINF()
            
            bool = snHasINF(self.getStruct);
        end
        
        function bool = hasPS(self)
            % BOOL = HASPS()
            
            bool = snHasPS(self.getStruct);
        end
        
        function bool = hasRAND(self)
            % BOOL = HASRAND()
            
            bool = snHasRAND(self.getStruct);
        end
        
        function bool = hasHOL(self)
            % BOOL = HASHOL()
            
            bool = snHasHOL(self.getStruct);
        end
        
        function bool = hasLCFS(self)
            % BOOL = HASLCFS()
            
            bool = snHasLCFS(self.getStruct);
        end
        
        function bool = hasSEPT(self)
            % BOOL = HASSEPT()
            
            bool = snHasSEPT(self.getStruct);
        end
        
        function bool = hasLEPT(self)
            % BOOL = HASLEPT()
            
            bool = snHasLEPT(self.getStruct);
        end
        
        function bool = hasSJF(self)
            % BOOL = HASSJF()
            
            bool = snHasSJF(self.getStruct);
        end
        
        function bool = hasLJF(self)
            % BOOL = HASLJF()
            
            bool = snHasLJF(self.getStruct);
        end
        
        function bool = hasMultiClassFCFS(self)
            % BOOL = HASMULTICLASSFCFS()
            
            bool = snHasMultiClassFCFS(self.getStruct);           
        end
        
        function bool = hasMultiServer(self)
            bool = snHasMultiServer(self.getStruct);           
        end
        
        function bool = hasSingleChain(self)
            % BOOL = HASSINGLECHAIN()
            
            bool = snHasSingleChain(self.getStruct);
        end
        
        function bool = hasMultiChain(self)
            % BOOL = HASMULTICHAIN()
            
             bool = snHasMultiChain(self.getStruct);
        end
        
        function bool = hasSingleClass(self)
            % BOOL = HASSINGLECLASS()
            
             bool = snHasSingleClass(self.getStruct);
        end
        
        function bool = hasMultiClass(self)
            % BOOL = HASMULTICLASS()
            
            bool = snHasMultiClass(self.getStruct);
        end
        
        function bool = hasProductFormSolution(self)
            % BOOL = HASPRODUCTFORMSOLUTION()
            
            bool = true;
            % language features
            featUsed = getUsedLangFeatures(self).list;
            if featUsed.Fork, bool = false; end
            if featUsed.Join, bool = false; end
            if featUsed.MMPP2, bool = false; end
            if featUsed.Normal, bool = false; end
            if featUsed.Pareto, bool = false; end
            if featUsed.Replayer, bool = false; end
            if featUsed.Uniform, bool = false; end
            if featUsed.Fork, bool = false; end
            if featUsed.Join, bool = false; end
            if featUsed.SchedStrategy_LCFS, bool = false; end % must be LCFS-PR
            if featUsed.SchedStrategy_SJF, bool = false; end
            if featUsed.SchedStrategy_LJF, bool = false; end
            if featUsed.SchedStrategy_DPS, bool = false; end
            if featUsed.SchedStrategy_GPS, bool = false; end
            if featUsed.SchedStrategy_SEPT, bool = false; end
            if featUsed.SchedStrategy_LEPT, bool = false; end
            if featUsed.SchedStrategy_HOL, bool = false; end
            % modelling features
            if self.hasMultiClassFCFS, bool = false; end
        end
                       
        
        function print(self)
            LINE2SCRIPT(self)
        end
        
    end
    
    methods (Static)
        function model = tandemPs(lambda,D)
            % MODEL = TANDEMPS(LAMBDA,D)
            
            model = Network.tandemPsInf(lambda,D,[]);
        end
        
        function model = tandemPsInf(lambda,D,Z)
            % MODEL = TANDEMPSINF(LAMBDA,D,Z)
            
            if nargin<3%~exist('Z','var')
                Z = [];
            end
            M  = size(D,1);
            Mz = size(Z,1);
            strategy = {};
            for i=1:Mz
                strategy{i} = SchedStrategy.INF;
            end
            for i=1:M
                strategy{Mz+i} = SchedStrategy.PS;
            end
            model = Network.tandem(lambda,[D;Z],strategy);
        end
        
        function model = tandemFcfs(lambda,D)
            % MODEL = TANDEMFCFS(LAMBDA,D)
            
            model = Network.tandemFcfsInf(lambda,D,[]);
        end
        
        function model = tandemFcfsInf(lambda,D,Z)
            % MODEL = TANDEMFCFSINF(LAMBDA,D,Z)
            
            if nargin<3%~exist('Z','var')
                Z = [];
            end
            M  = size(D,1);
            Mz = size(Z,1);
            strategy = {};
            for i=1:Mz
                strategy{i} = SchedStrategy.INF;
            end
            for i=1:M
                strategy{Mz+i} = SchedStrategy.FCFS;
            end
            model = Network.tandem(lambda,[D;Z],strategy);
        end
        
        function model = tandem(lambda,S,strategy)
            % MODEL = TANDEM(LAMBDA,S,STRATEGY)
            
            % S(i,r) - mean service time of class r at station i
            % lambda(r) - number of jobs of class r
            % station(i) - scheduling strategy at station i
            model = Network('Model');
            [M,R] = size(S);
            node{1} = Source(model, 'Source');
            for i=1:M
                switch SchedStrategy.toId(strategy{i})
                    case SchedStrategy.ID_INF
                        node{end+1} = DelayStation(model, ['Station',num2str(i)]);
                    otherwise
                        node{end+1} = Queue(model, ['Station',num2str(i)], strategy{i});
                end
            end
            node{end+1} = Sink(model, 'Sink');
            P = cellzeros(R,R,M+2,M+2);
            for r=1:R
                jobclass{r} = OpenClass(model, ['Class',num2str(r)], 0);
                P{r,r} = circul(length(node)); P{r}(end,:) = 0;
            end
            for r=1:R
                node{1}.setArrival(jobclass{r}, Exp.fitMean(1/lambda(r)));
                for i=1:M
                    node{1+i}.setService(jobclass{r}, Exp.fitMean(S(i,r)));
                end
            end
            model.link(P);
        end
        
        function model = productForm(N,D,Z)
            if nargin<3
                Z = [];
            end
            model = Network.cyclicPsInf(N,D,Z);
        end
        
        function model = cyclicPs(N,D)
            % MODEL = CYCLICPS(N,D)
            
            model = Network.cyclicPsInf(N,D,[]);
        end
        
        function model = cyclicPsInf(N,D,Z)
            % MODEL = CYCLICPSINF(N,D,Z)
            if nargin<3
                Z = [];
            end
            M  = size(D,1);
            Mz = size(Z,1);
            strategy = {};
            for i=1:Mz
                strategy{i} = SchedStrategy.INF;
            end
            for i=1:M
                strategy{Mz+i} = SchedStrategy.PS;
            end
            model = Network.cyclic(N,[Z;D],strategy);
        end
        
        function model = cyclicFcfs(N,D)
            % MODEL = CYCLICFCFS(N,D)
            
            model = Network.cyclicFcfsInf(N,D,[]);
        end
        
        function model = cyclicFcfsInf(N,D,Z)
            % MODEL = CYCLICFCFSINF(N,D,Z)
            
            if nargin<3%~exist('Z','var')
                Z = [];
            end
            M  = size(D,1);
            Mz = size(Z,1);
            strategy = {};
            for i=1:Mz
                strategy{i} = SchedStrategy.INF;
            end
            for i=1:M
                strategy{Mz+i} = SchedStrategy.FCFS;
            end
            model = Network.cyclic(N,[Z;D],strategy);
        end
        
        function model = cyclic(N,D,strategy)
            % MODEL = CYCLIC(N,D,STRATEGY)
            
            % L(i,r) - demand of class r at station i
            % N(r) - number of jobs of class r
            % strategy(i) - scheduling strategy at station i
            model = Network('Model');
            [M,R] = size(D);
            node = {};
            nQ = 0; nD = 0;
            for i=1:M
                switch SchedStrategy.toId(strategy{i})
                    case SchedStrategy.ID_INF
                        nD = nD + 1;
                        node{end+1} = DelayStation(model, ['Delay',num2str(nD)]);
                    otherwise
                        nQ = nQ + 1;
                        node{end+1} = Queue(model, ['Queue',num2str(nQ)], strategy{i});
                end
            end
            P = cellzeros(R,M);
            for r=1:R
                jobclass{r} = ClosedClass(model, ['Class',num2str(r)], N(r), node{1}, 0);
                P{r,r} = circul(M);
            end
            for i=1:M
                for r=1:R
                    node{i}.setService(jobclass{r}, Exp.fitMean(D(i,r)));
                end
            end
            model.link(P);
        end
        
        function P = serialRouting(varargin)
            % P = SERIALROUTING(VARARGIN)
            
            if length(varargin)==1
                varargin = varargin{1};
            end
            model = varargin{1}.model;
            P = zeros(model.getNumberOfNodes);
            for i=1:length(varargin)-1
                P(varargin{i},varargin{i+1})=1;
            end
            if ~isa(varargin{end},'Sink')
                P(varargin{end},varargin{1})=1;
            end
            P = P ./ repmat(sum(P,2),1,length(P));
            P(isnan(P)) = 0;
        end
        
        function printInfGen(Q,SS)
            % PRINTINFGEN(Q,SS)
            SolverCTMC.printInfGen(Q,SS);
        end
        
        function printEventFilt(sync,D,SS,myevents)
            % PRINTEVENTFILT(SYNC,D,SS,MYEVENTS)
            SolverCTMC.printEventFilt(sync,D,SS,myevents);
        end
        
        
        function ret = exportNetworkStruct(qn, language)
            % @todo unfinished
            
            ret = javaObject('java.util.HashMap');
            switch language
                case {'java','Java'}
                    fieldNames = fields(qn);
                    for f=1:length(fieldNames)
                        switch fieldNames{f}
                            case 'sync'
                                %noop
                            otherwise
                                field = qn.(fieldNames{f});
                                
                        end
                        ret.put(fieldNames{f},exportJava(field));
                    end
            end
            
        end
                
    end
end
