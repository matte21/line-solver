classdef SolverLN < LayeredNetworkSolver & EnsembleSolver
    % LINE native solver for layered networks.
    %
    % Copyright (c) 2012-2022, Imperial College London
    % All rights reserved.

    properties
        initNodeAvgTable = {};
        initCallAvgTable = {};
        insist = true;
    end

    properties (Hidden)
        successors = {};
        lqn; % lqn data structure
        idxhash; % ensemble model associated to host or task
        svctmatrix; % auxiliary matrix to determine entry svct
        routereset; % models that require hard reset of service chains
        svcreset; % models that require hard reset of service process
        maxIterErr;
    end

    properties (Hidden) % performance metrics and related processes
        svcreset_classes;
        util;
        tput;
        svct; % this is the response time (not the residence time)
        svctproc;
        svctcdf;
        idlet;
        idletproc;
        callresidt;
        tputproc;
        thinkproc;
        callresidtproc;
        entryproc
        entryCdfRespT;
        callresidtcdf;
        cdf
        hasConverged;
    end

    properties (Hidden) % registries of quantities to update at every iteration
        arvupdmap; % [modelidx, actidx, node, class]
        svcupdmap; % [modelidx, actidx, node, class]
        svctmap; % [modelidx, actidx, node, class]
        callupdmap;  % [modelidx, callidx, node, class]
        callresidtmap;  % [modelidx, callidx, node, class]
        routeupdmap; % [modelidx, actidxfrom, actidxto, nodefrom, nodeto, classfrom, classto]
        unique_routeupdmap;
    end

    methods


        function self = reset(self)
            self.initNodeAvgTable = {};
            self.initCallAvgTable = {};
        end

        function self = SolverLN(lqnmodel, solverFactory, varargin)
            % SELF = SOLVERLN(MODEL,SOLVERFACTORY,VARARGIN)

            self@LayeredNetworkSolver(lqnmodel, mfilename);
            self@EnsembleSolver(lqnmodel, mfilename);

            if nargin>1 && isstruct(solverFactory)
                options = solverFactory;
                self.setOptions(options);
                solverFactory = @(m) ifthenelse(m.hasFork(), SolverMVA(m,'verbose',false), SolverNC(m,'verbose',false));
            else
                self.setOptions(SolverLN.defaultOptions);
                if nargin>2
                    if ischar(solverFactory)
                        inputvar = {solverFactory,varargin{:}};
                        solverFactory = @(m) ifthenelse(m.hasFork(), SolverMVA(m,'verbose',false), SolverNC(m,'verbose',false));
                    else
                        inputvar = varargin;
                    end
                    Solver.parseOptions(inputvar, self.defaultOptions);
                    self.setOptions(Solver.parseOptions(inputvar, self.defaultOptions));
                end
            end

            lqn = lqnmodel.getStruct;
            self.lqn = lqn;

            % initialize call response times
            self.entryCdfRespT = cell(length(lqn.nentries),1);
            self.hasConverged = 0;
            self.svctproc = lqn.hostdem;
            self.thinkproc = lqn.think;
            self.callresidtproc = cell(lqn.ncalls,1);
            for cidx = 1:lqn.ncalls
                self.callresidtproc{cidx} = lqn.hostdem{lqn.callpair(cidx,2)};
            end

            % build layering
            buildLayers(self);

            self.routereset = unique(self.idxhash(self.routeupdmap(:,1)))';
            self.svcreset = unique(self.idxhash(self.svcupdmap(:,1)))';
            self.svcreset = union(self.svcreset,unique(self.idxhash(self.callupdmap(:,1)))');

            for e=1:self.getNumberOfModels
                if nargin == 1
                    solverFactory = @(m) ifthenelse(m.hasFork(), SolverMVA(m,'verbose',false), SolverNC(m,'verbose',false,'method','adaptive'));
                end
                self.setSolver(solverFactory(self.ensemble{e}),e);
            end
        end

        function initFromRawAvgTables(self, NodeAvgTable, CallAvgTable)
            line_error(mfilename,'initFromRawAvgTables not yet available');
        end

        function paramFromRawAvgTables(self, NodeAvgTable, CallAvgTable)
            line_error(mfilename,'paramFromRawAvgTables not yet available');
        end

        function bool = converged(self, it) % convergence test at iteration it
            % BOOL = CONVERGED(IT) % CONVERGENCE TEST AT ITERATION IT
            bool = false;

            if it>=30 % assume steady-state
                for e=1:length(self.ensemble)
                    kmax = 5; % number of previous solutions to avg
                    w = 1/(kmax+1); % start averaging after initial transient
                    self.results{end,e}.QN = w*self.results{end,e}.QN;
                    self.results{end,e}.UN = w*self.results{end,e}.UN;
                    self.results{end,e}.RN = w*self.results{end,e}.RN;
                    self.results{end,e}.TN = w*self.results{end,e}.TN;
                    self.results{end,e}.AN = w*self.results{end,e}.AN;
                    self.results{end,e}.WN = w*self.results{end,e}.WN;
                    for k=1:kmax
                        self.results{end,e}.QN = self.results{end,e}.QN + self.results{end-k,e}.QN * w;
                        self.results{end,e}.UN = self.results{end,e}.UN + self.results{end-k,e}.UN * w;
                        self.results{end,e}.RN = self.results{end,e}.RN + self.results{end-k,e}.RN * w;
                        self.results{end,e}.TN = self.results{end,e}.TN + self.results{end-k,e}.TN * w;
                        self.results{end,e}.AN = self.results{end,e}.AN + self.results{end-k,e}.AN * w;
                        self.results{end,e}.WN = self.results{end,e}.WN + self.results{end-k,e}.WN * w;
                    end
                end
            end

            if it>1
                self.maxIterErr(it) = 0;
                E = size(self.results,2);
                for e = 1:E
                    metric = self.results{end,e}.QN;
                    metric_1 = self.results{end-1,e}.QN;
                    N = sum(self.ensemble{e}.getNumberOfJobs);
                    if N>0
                        %                         IterErr = nanmax(abs(metric(:) - metric_1(:)))/N;
                        try
                            IterErr = nanmax(abs(metric(:) - metric_1(:)))/N;
                        catch
                            IterErr = 0;
                        end
                        self.maxIterErr(it) = self.maxIterErr(it) + IterErr;
                    end
                end
                if self.options.verbose
                    line_printf(sprintf('\bError: %f.',self.maxIterErr(it)/E));
                    if it==30
                        if self.options.verbose
                            line_printf( ' Starting moving window to help convergence.');
                        end
                    end
                end
                % check if unchanged in the last two iterations
                if it>2 && self.maxIterErr(it) < self.options.iter_tol && self.maxIterErr(it-1) < self.options.iter_tol&& self.maxIterErr(it-1) < self.options.iter_tol
                    self.hasConverged = 1;
                    if self.insist
                        % do a hard reset to check that this is really the fixed point
                        for e=1:length(self.ensemble)
                            self.ensemble{e}.reset();
                        end
                        if self.options.verbose
                            line_printf(sprintf('\b Testing convergence.')); %Deep reset.');
                        end
                        self.insist = false;
                    else
                        if self.options.verbose
                            line_printf( sprintf('\nSolverLN completed in %d iterations.',size(self.results,1)));
                        end
                        bool = true;
                    end
                else
                    self.insist = true; %This is to run multiple convergence tests
                end
            end
        end

        function init(self) % operations before starting to iterate
            % INIT() % OPERATIONS BEFORE STARTING TO ITERATE
            self.unique_routeupdmap = unique(self.routeupdmap(:,1))';
            self.tput = zeros(self.lqn.nidx,1);
            self.util = zeros(self.lqn.nidx,1);
            self.svct = zeros(self.lqn.nidx,1);
            self.svctmatrix = getServiceMatrix(self);
        end


        function pre(self, it) % operations before an iteration
            % PRE(IT) % OPERATIONS BEFORE AN ITERATION

            %nop
        end

        function [result, runtime] = analyze(self, it, e)
            % [RESULT, RUNTIME] = ANALYZE(IT, E)
            T0 = tic;
            result = struct();
            [result.QN, result.UN, result.RN, result.TN, result.AN, result.WN] = self.solvers{e}.getAvg();
            runtime = toc(T0);
        end

        function post(self, it) % operations after an iteration
            % POST(IT) % OPERATIONS AFTER AN ITERATION

            % store the results
            self.updateMetrics(it); % recalculate service and response times

            % recompute think times
            self.updateThinkTimes(it);

            % update the model parameters
            self.updateLayers(it);

            % update entry routing probabilities
            self.updateRoutingProbabilities(it);

            % reset all non-pure layers
            for e= self.routereset
                self.ensemble{e}.refreshChains();
                self.solvers{e}.reset();
            end

            for e= self.svcreset
                %if it==1
                %    self.svcreset_classes{e}=unique(union(self.svcupdmap(self.idxhash(self.svcupdmap(:,1))==e,3),self.callupdmap(self.idxhash(self.callupdmap(:,1))==e,4)));
                %    self.ensemble{e}.refreshService(1:self.ensemble{e}.getNumberOfStations, self.svcreset_classes{e}(:)');
                %end
                switch self.solvers{e}.name
                    case {'SolverMVA', 'SolverNC'} %no need to refresh phases
                        refreshRates(self.ensemble{e}); % note: this does not refresh the sn.proc field, only sn.rates and sn.scv
                    otherwise
                        refreshService(self.ensemble{e});
                end
                self.solvers{e}.reset(); % commenting this out des not seem to produce a problem, but it goes faster with it
            end

            if it==1
                % now disable all solver support checks for future iterations
                for e=1:length(self.ensemble)
                    self.solvers{e}.setDoChecks(false);
                end
            end
        end

        updateThinkTimes(self, it);
        updateMetrics(self, it);
        updateRoutingProbabilities(self, it);

        function finish(self) % operations after iterations are completed
            % FINISH() % OPERATIONS AFTER INTERATIONS ARE COMPLETED
            if self.options.verbose
                line_printf('\n');
            end
            E = size(self.results,2);
            for e=1:E
                s = self.solvers{e};
                s.getAvgTable();
                self.solvers{e} = s;
            end
            self.model.ensemble = self.ensemble;
        end


        function varargout = getAvg(varargin)
            % [QN,UN,RN,TN,AN,WN] = GETAVG(SELF,~,~,~,~,USELQNSNAMING)
            [varargout{1:nargout}] = getEnsembleAvg( varargin{:} );
        end


        function [QN,UN,RN,TN,AN,WN] = getEnsembleAvg(self,~,~,~,~, useLQNSnaming)
            % [QN,UN,RN,TN,AN,WN] = GETENSEMBLEAVG(SELF,~,~,~,~,USELQNSNAMING)

            if nargin < 5
                useLQNSnaming = false;
            end

            iterate(self); % run iterations
            QN  = nan(self.lqn.nidx,1);
            UN  = nan(self.lqn.nidx,1);
            RN  = nan(self.lqn.nidx,1);
            TN  = nan(self.lqn.nidx,1);
            PN  = nan(self.lqn.nidx,1); % utilization will be first stored here
            SN  = nan(self.lqn.nidx,1); % response time will be first stored here
            WN  = nan(self.lqn.nidx,1); % residence time
            AN  = nan(self.lqn.nidx,1); % not available yet
            E = length(self.ensemble);
            for e=1:E
                clientIdx = self.ensemble{e}.attribute.clientIdx;
                serverIdx = self.ensemble{e}.attribute.serverIdx;
                sourceIdx = self.ensemble{e}.attribute.sourceIdx;
                % determine processor metrics
                if self.ensemble{e}.stations{serverIdx}.attribute.ishost
                    hidx = self.ensemble{e}.stations{serverIdx}.attribute.idx;
                    TN(hidx) = 0;
                    PN(hidx) = 0;
                    for c=1:self.ensemble{e}.getNumberOfClasses
                        if self.ensemble{e}.classes{c}.completes
                            t = 0;
                            u = 0;
                            if ~isnan(clientIdx)
                                t = max(t, self.results{end,e}.TN(clientIdx,c));
                            end
                            if ~isnan(sourceIdx)
                                t = max(t, self.results{end,e}.TN(sourceIdx,c));
                            end
                            TN(hidx) = TN(hidx) + nanmax(t,self.results{end,e}.TN(serverIdx,c));
                        end
                        type = self.ensemble{e}.classes{c}.attribute(1);
                        switch type
                            case LayeredNetworkElement.ACTIVITY
                                aidx = self.ensemble{e}.classes{c}.attribute(2);
                                tidx = self.lqn.parent(aidx);
                                if isnan(PN(aidx)), PN(aidx)=0; end
                                if isnan(PN(tidx)), PN(tidx)=0; end
                                PN(aidx) = PN(aidx) + self.results{end,e}.UN(serverIdx,c);
                                PN(tidx) = PN(tidx) + self.results{end,e}.UN(serverIdx,c);
                                PN(hidx) = PN(hidx) + self.results{end,e}.UN(serverIdx,c);
                        end
                    end
                end

                % determine remaining metrics
                for c=1:self.ensemble{e}.getNumberOfClasses
                    type = self.ensemble{e}.classes{c}.attribute(1);
                    switch type
                        case LayeredNetworkElement.TASK
                            tidx = self.ensemble{e}.classes{c}.attribute(2);
                            if self.ensemble{e}.stations{serverIdx}.attribute.ishost
                                if isnan(TN(tidx))
                                    % store the result in the processor
                                    % model
                                    TN(tidx) = self.results{end,e}.TN(clientIdx,c);
                                end
                            else
                                % nop
                            end
                        case LayeredNetworkElement.ENTRY
                            eidx = self.ensemble{e}.classes{c}.attribute(2);
                            tidx = self.lqn.parent(eidx);
                            SN(eidx) = self.svct(eidx);
                            if self.ensemble{e}.stations{serverIdx}.attribute.ishost
                                if isnan(TN(eidx))
                                    % store the result in the processor model
                                    if isnan(TN(eidx)), TN(eidx)=0; end
                                    TN(eidx) = self.results{end,e}.TN(clientIdx,c);
                                end
                            else
                                % nop
                            end
                        case LayeredNetworkElement.CALL
                            cidx = self.ensemble{e}.classes{c}.attribute(2);
                            aidx = self.lqn.callpair(cidx,1);
                            SN(aidx) = SN(aidx) + self.results{end,e}.RN(serverIdx,c) * self.lqn.callproc{cidx}.getMean();
                            if isnan(QN(aidx)), QN(aidx)=0; end
                            QN(aidx) = QN(aidx) + self.results{end,e}.QN(serverIdx,c);
                        case LayeredNetworkElement.ACTIVITY
                            aidx = self.ensemble{e}.classes{c}.attribute(2);
                            tidx = self.lqn.parent(aidx);
                            QN(tidx) = QN(tidx) + self.results{end,e}.QN(serverIdx,c);
                            if isnan(TN(aidx)), TN(aidx)=0; end
                            if isnan(QN(aidx)), QN(aidx)=0; end
                            switch self.ensemble{e}.classes{c}.type
                                case JobClassType.CLOSED
                                    TN(aidx) = TN(aidx) + self.results{end,e}.TN(serverIdx,c);
                                case JobClassType.OPEN
                                    TN(aidx) = TN(aidx) + self.results{end,e}.TN(sourceIdx,c);
                            end
                            %                            SN(aidx) = self.svct(aidx);
                            if isnan(SN(aidx)), SN(aidx)=0; end
                            SN(aidx) = SN(aidx) + self.results{end,e}.RN(serverIdx,c);
                            if isnan(RN(aidx)), RN(aidx)=0; end
                            RN(aidx) = RN(aidx) + self.results{end,e}.RN(serverIdx,c);
                            if isnan(WN(aidx)), WN(aidx)=0; end
                            if isnan(WN(tidx)), WN(tidx)=0; end
                            WN(aidx) = WN(aidx) + self.results{end,e}.WN(serverIdx,c);
                            WN(tidx) = WN(tidx) + self.results{end,e}.WN(serverIdx,c);
                            if isnan(QN(aidx)), QN(aidx)=0; end
                            QN(aidx) = QN(aidx) + self.results{end,e}.QN(serverIdx,c);
                    end
                end
            end

            for e=1:self.lqn.nentries
                eidx = self.lqn.eshift + e;
                tidx = self.lqn.parent(eidx);
                if isnan(UN(tidx)), UN(tidx)=0; end
                UN(eidx) = TN(eidx)*SN(eidx);
                for aidx=self.lqn.actsof{tidx}
                    UN(aidx) = TN(aidx)*SN(aidx);
                end
                UN(tidx) = UN(tidx) + UN(eidx);
            end

            if ~useLQNSnaming % if LN
                QN = UN;
                UN = PN;
                RN = SN;
            end
        end

        %         function [QN,UN,RN,TN] = getStageAvg(self,~,~,~,~)
        %             % [QN,UN,RN,TN] = GETSTAGEAVG(SELF,~,~,~,~)
        %
        %             runAnalyzer(self); % run iterations
        %             E = length(self.ensemble);
        %             QN  = zeros(E,self.lqn.nidx+self.lqn.ncalls);
        %             UN  = zeros(E,self.lqn.nidx+self.lqn.ncalls);
        %             RN  = zeros(E,self.lqn.nidx+self.lqn.ncalls);
        %             TN  = zeros(E,self.lqn.nidx+self.lqn.ncalls);
        %             for e=1:E
        %                 clientIdx = self.ensemble{e}.attribute.clientIdx;
        %                 serverIdx = self.ensemble{e}.attribute.serverIdx;
        %                 sourceIdx = self.ensemble{e}.attribute.sourceIdx;
        %                 for c=1:self.ensemble{e}.getNumberOfClasses
        %                     type = self.ensemble{e}.classes{c}.attribute(1);
        %                     switch type
        %                         case LayeredNetworkElement.TASK
        %                             tidx = self.ensemble{e}.classes{c}.attribute(2);
        %                             if strcmp(self.lqn.sched(tidx), SchedStrategy.REF)
        %                                 TN(e,tidx) = self.results{end,e}.TN(clientIdx,c);
        %                             end
        %                             UN(e,tidx) = NaN;
        %                             RN(e,tidx) = NaN;
        %                             QN(e,tidx) = NaN;
        %                             %if ~isnan(clientIdx)
        %                             %    TN(e,tidx) = max(self.results{end,e}.TN(clientIdx,c), TN(e,tidx));
        %                             %end
        %                             %UN(e,tidx) = self.util(tidx);
        %                             %RN(e,tidx) = NaN;
        %                             %QN(e,tidx) = self.results{end,e}.QN(serverIdx,c);
        %                         case LayeredNetworkElement.ENTRY
        %                             %eidx = self.ensemble{e}.classes{c}.attribute(2);
        %                             %RN(e,eidx) = NaN;
        %                             %UN(e,eidx) = self.results{end,e}.UN(serverIdx,c);
        %                             %QN(e,eidx) = self.results{end,e}.QN(serverIdx,c);
        %                             %TN(e,eidx) = self.results{end,e}.TN(clientIdx,c);
        %                             %if ~isnan(clientIdx)
        %                             %    TN(e,eidx) = max(self.results{end,e}.TN(clientIdx,c), TN(e,eidx));
        %                             %end
        %                         case LayeredNetworkElement.CALL
        %                             cidx = self.ensemble{e}.classes{c}.attribute(2);
        %                             idx = self.lqn.nidx + cidx;
        %                             aidx = self.lqn.callpair(cidx,1);
        %                             tidx = self.lqn.parent(aidx);
        %                             % contribution of call to task
        %                             %UN(e,tidx) = UN(e,tidx) + self.results{end,e}.UN(serverIdx,c);
        %                             %QN(e,tidx) = QN(e,tidx) + self.results{end,e}.QN(serverIdx,c);
        %                             switch self.ensemble{e}.classes{c}.type
        %                                 case JobClassType.CLOSED
        %                                     if self.ensemble{e}.classes{c}.completes
        %                                         %     TN(e,tidx) = TN(e,tidx) + max(self.results{end,e}.TN(serverIdx,c), self.results{end,e}.TN(clientIdx,c));
        %                                     end
        %                                     %TN(e,aidx) = TN(e,aidx) + self.results{end,e}.TN(serverIdx,c);
        %                                     TN(e,idx) = TN(e,idx) + self.results{end,e}.TN(serverIdx,c);
        %                                     %TN(e,idx) = max(self.results{end,e}.TN(serverIdx,c), self.results{end,e}.TN(clientIdx,c));
        %                                 case JobClassType.OPEN
        %                                     if self.ensemble{e}.classes{c}.completes
        %                                         %    TN(e,tidx) = TN(e,tidx) + self.results{end,e}.TN(sourceIdx,c);
        %                                     end
        %                                     %TN(e,aidx) = TN(e,aidx) + self.results{end,e}.TN(sourceIdx,c);
        %                                     TN(e,idx) = TN(e,idx) + self.results{end,e}.TN(sourceIdx,c);
        %                                     %TN(e,idx) = max(self.results{end,e}.TN(serverIdx,c), self.results{end,e}.TN(sourceIdx,c));
        %                             end
        %                             %RN(e,aidx) = RN(e,aidx) + self.results{end,e}.RN(serverIdx,c);
        %                             %UN(e,aidx) = UN(e,aidx) + self.results{end,e}.UN(serverIdx,c);
        %                             %QN(e,aidx) = QN(e,aidx) + self.results{end,e}.QN(serverIdx,c);
        %                             RN(e,idx) = RN(e,idx) + self.results{end,e}.RN(serverIdx,c);
        %                             UN(e,idx) = UN(e,idx) + self.results{end,e}.UN(serverIdx,c);
        %                             QN(e,idx) = QN(e,idx) + self.results{end,e}.QN(serverIdx,c);
        %                         case LayeredNetworkElement.ACTIVITY
        %                             aidx = self.ensemble{e}.classes{c}.attribute(2);
        %                             tidx = self.lqn.parent(aidx);
        %                             % contribution of activity to task
        %                             %UN(e,tidx) = UN(e,tidx) + self.results{end,e}.UN(serverIdx,c);
        %                             %QN(e,tidx) = QN(e,tidx) + self.results{end,e}.QN(serverIdx,c);
        %                             switch self.ensemble{e}.classes{c}.type
        %                                 case JobClassType.CLOSED
        %                                     if self.ensemble{e}.classes{c}.completes
        %                                         %    TN(e,tidx) = TN(e,tidx) + max(self.results{end,e}.TN(serverIdx,c), self.results{end,e}.TN(clientIdx,c));
        %                                     end
        %                                     TN(e,aidx) = TN(e,aidx) + self.results{end,e}.TN(serverIdx,c);
        %                                 case JobClassType.OPEN
        %                                     if self.ensemble{e}.classes{c}.completes
        %                                         %    TN(e,tidx) = TN(e,tidx) + self.results{end,e}.TN(sourceIdx,c);
        %                                     end
        %                                     %TN(e,aidx) = TN(e,aidx) + self.results{end,e}.TN(sourceIdx,c);
        %                                     TN(e,aidx) = TN(e,aidx) + self.results{end,e}.TN(sourceIdx,c);
        %                             end
        %                             RN(e,aidx) = RN(e,aidx) + self.results{end,e}.RN(serverIdx,c);
        %                             UN(e,aidx) = UN(e,aidx) + self.results{end,e}.UN(serverIdx,c);
        %                             QN(e,aidx) = QN(e,aidx) + self.results{end,e}.QN(serverIdx,c);
        %                     end
        %                 end
        %             end
        %         end

        %        function [NodeAvgTable, CallAvgTable] = getRawAvgTables(self)
        %            line_error(mfilename,'paramFromRawAvgTables not yet available');
        %        end

        function [cdfRespT] = getCdfRespT(self)
            if isempty(self.entryCdfRespT{1}) 
                curMethod = self.getOptions.method;
                self.options.method = 'moment3';
                self.getAvgTable;
                self.options.method = curMethod;
            end
            cdfRespT = self.entryCdfRespT;
        end

    end

    methods (Hidden)
        buildLayers(self, lqn, resptproc, callresidtproc);
        buildLayersRecursive(self, idx, callers, ishostlayer);
        updateLayers(self, it);
        U = getServiceMatrixRecursion(self, lqn, aidx, eidx, U);
        U = getServiceMatrix(self)
    end

    methods (Static)
        function [bool, featSupported] = supports(model)
            % [BOOL, FEATSUPPORTED] = SUPPORTS(MODEL)

            featUsed = model.getUsedLangFeatures();
            featSupported = SolverFeatureSet;
            featSupported.setTrue({'Sink','Source','Queue',...
                'Coxian','Erlang','Exponential','HyperExp',...
                'Buffer','Server','JobSink','RandomSource','ServiceTunnel',...
                'Fork','Forker','Join','Joiner',...
                'SchedStrategy_PS','SchedStrategy_FCFS','ClosedClass','OpenClass'});
            bool = true;
            for e = 1:model.getNumberOfLayers()
                bool = bool && SolverFeatureSet.supports(featSupported, featUsed{e});
            end
        end
    end

    methods (Static)
        function options = defaultOptions()
            % OPTIONS = DEFAULTOPTIONS()
            options = lineDefaults('LN');
            %            options.config.reset = 'shallow';
        end
    end
end
