classdef NetworkSolver < Solver
    % Abstract class for solvers applicable to Network models.
    %
    % Copyright (c) 2012-2022, Imperial College London
    % All rights reserved.
    
    
    properties (Access = protected)
        handles; % performance metric handles
    end
    
    methods
        function self = NetworkSolver(model, name, options)
            % SELF = NETWORKSOLVER(MODEL, NAME, OPTIONS)
            
            % Construct a NetworkSolver with given model, name and options
            % data structure.
            self@Solver(model, name);
            if isempty(model)
                line_error(mfilename,'The model supplied in input is empty');
            end
            if nargin>=3 %exist('options','var'),
                self.setOptions(options);
            end
            self.result = [];
            
            [Q,U,R,T,A] = model.getAvgHandles;
            self.setAvgHandles(Q,U,R,T,A);
            
            [Qt,Ut,Tt] = model.getTranHandles;
            self.setTranHandles(Qt,Ut,Tt);
            
            if ~model.hasStruct
                self.model.refreshStruct(); % force model to refresh
            end
        end
        
        function self = setTranHandles(self,Qt,Ut,Tt)
            self.handles.Qt = Qt;
            self.handles.Ut = Ut;
            self.handles.Tt = Tt;
        end
        
        function self = setAvgHandles(self,Q,U,R,T,A)
            self.handles.Q = Q;
            self.handles.U = U;
            self.handles.R = R;
            self.handles.T = T;
            self.handles.A = A;
        end
        
        function [Qt,Ut,Tt] = getTranHandles(self)
            Qt = self.handles.Qt;
            Ut = self.handles.Ut;
            Tt = self.handles.Tt;
        end
        
        function [Q,U,R,T,A] = getAvgHandles(self)
            Q = self.handles.Q;
            U = self.handles.U;
            R = self.handles.R;
            T = self.handles.T;
            A = self.handles.A;
        end
        
        function Q = getAvgQLenHandles(self)
            Q = self.handles.Q;
        end
        
        function R = getAvgRespTHandles(self)
            R = self.handles.R;
        end
        
        function U = getAvgUtilHandles(self)
            U = self.handles.U;
        end
        
        function T = getAvgTputHandles(self)
            T = self.handles.T;
        end
    end
    
    
    methods (Access = 'protected')
        function bool = hasAvgResults(self)
            % BOOL = HASAVGRESULTS()
            
            % Returns true if the solver has computed steady-state average metrics.
            bool = false;
            if self.hasResults
                if isfield(self.result,'Avg')
                    bool = true;
                end
            end
        end
        
        function bool = hasTranResults(self)
            % BOOL = HASTRANRESULTS()
            
            % Return true if the solver has computed transient average metrics.
            bool = false;
            if self.hasResults
                if isfield(self.result,'Tran')
                    if isfield(self.result.Tran,'Avg')
                        bool = isfield(self.result.Tran.Avg,'Qt');
                    end
                end
            end
        end
        
        function bool = hasDistribResults(self)
            % BOOL = HASDISTRIBRESULTS()
            
            % Return true if the solver has computed steady-state distribution metrics.
            bool = false;
            if self.hasResults
                bool = isfield(self.result.Distrib,'C');
            end
        end
    end
    
    methods (Sealed)       
        function setOptions(self, options)
            % SETOPTIONS(OPTIONS)
            % Assign the solver options
            
            self.checkOptions(options);
            setOptions@Solver(self,options);
        end
        
        function self = updateModel(self, model)
            % SELF = UPDATEMODEL(MODEL)
            
            % Assign the model to be solved.
            self.model = model;
        end
        
        function ag = getAG(self)
            % AG = GETAG()
            
            % Get agent representation
            ag = self.model.getAG();
        end
        
        function QN = getAvgQLen(self)
            % QN = GETAVGQLEN()
            
            % Compute average queue-lengths at steady-state
            Q = getAvgQLenHandles(self);
            [QN,~,~,~] = self.getAvg(Q,[],[],[]);
        end
        
        function UN = getAvgUtil(self)
            % UN = GETAVGUTIL()
            
            % Compute average utilizations at steady-state
            U = getAvgUtilHandles(self);
            [~,UN,~,~] = self.getAvg([],U,[],[]);
        end
        
        function RN = getAvgRespT(self)
            % RN = GETAVGRESPT()
            
            % Compute average response times at steady-state
            R = getAvgRespTHandles(self);
            [~,~,RN,~] = self.getAvg([],[],R,[]);
        end
        
        function WN = getAvgWaitT(self)
            % RN = GETAVGWAITT()
            % Compute average waiting time in queue excluding service
            R = getAvgRespTHandles(self);
            [~,~,RN,~] = self.getAvg([],[],R,[]);
            if isempty(RN)
                WN = [];
                return
            end
            sn = self.model.getStruct;
            WN = RN - 1./ sn.rates(:);
            WN(sn.nodetype==NodeType.Source) = 0;
        end
        
        function TN = getAvgTput(self)
            % TN = GETAVGTPUT()
            
            % Compute average throughputs at steady-state
            T = getAvgTputHandles(self);
            [~,~,~,TN] = self.getAvg([],[],[],T);
        end
        
        function AN = getAvgArvR(self)
            % AN = GETAVGARVR()
            
            % Compute average arrival rate at steady-state
            M = sn.nstations;
            K = sn.nclasses;
            T = getAvgTputHandles(self);
            [~,~,~,TN] = self.getAvg([],[],[],T);
            sn = self.model.getStruct;
            if ~isempty(T)
                AN = zeros(M,K);
                for k=1:K
                    for i=1:M
                        for j=1:M
                            for r=1:K
                                AN(i,k) = AN(i,k) + TN(j,r)*sn.rt((j-1)*K+r, (i-1)*K+k);
                            end
                        end
                    end
                end
            end
        end       
        
        % also accepts a cell array with the handlers in it
        [QN,UN,RN,TN,AN,WN]       = getAvg(self,Q,U,R,T,A);
        [QN,UN,RN,TN,AN,WN]       = getAvgNode(self,Q,U,R,T,A);
        
        [AvgTable,QT,UT,RT,TT,AT] = getAvgTable(self,Q,U,R,T,A,keepDisabled);
        
        [AvgTable,QT] = getAvgQLenTable(self,Q,keepDisabled);
        [AvgTable,UT] = getAvgUtilTable(self,U,keepDisabled);
        [AvgTable,RT] = getAvgRespTTable(self,R,keepDisabled);
        [AvgTable,TT] = getAvgTputTable(self,T,keepDisabled);
        
        [NodeAvgTable,QTn,UTn,RTn,TTn] = getAvgNodeTable(self,Q,U,R,T,A,keepDisabled);
        [AvgChain,QTc,UTc,RTc,WTc,TTc] = getAvgChainTable(self,Q,U,R,T);
        
        [QNc,UNc,RNc,TNc]   = getAvgChain(self,Q,U,R,T);
        [AN]                = getAvgArvRChain(self,Q);
        [QN]                = getAvgQLenChain(self,Q);
        [UN]                = getAvgUtilChain(self,U);
        [RN]                = getAvgRespTChain(self,R);
        [TN]                = getAvgTputChain(self,T);
        [CNc,XNc]           = getAvgSys(self,R,T);
        [CT,XT]             = getAvgSysTable(self,R,T);
        [RN]                = getAvgSysRespT(self,R);
        [TN]                = getAvgSysTput(self,T);
        [QNt,UNt,TNt]       = getTranAvg(self,Qt,Ut,Tt);
        
        function self = setAvgResults(self,Q,U,R,T,C,X,runtime,method)
            % SELF = SETAVGRESULTS(SELF,Q,U,R,T,C,X,RUNTIME,METHOD)
            % Store average metrics at steady-state
            self.result.('solver') = getName(self);
            if nargin<9 %~exist('method','var')
                method = getOptions(self).method;
            end
            self.result.Avg.('method') = method;
            if isnan(Q), Q=[]; end
            if isnan(R), R=[]; end
            if isnan(T), T=[]; end
            if isnan(U), U=[]; end
            if isnan(X), X=[]; end
            if isnan(C), C=[]; end
            self.result.Avg.Q = real(Q);
            self.result.Avg.R = real(R);
            self.result.Avg.X = real(X);
            self.result.Avg.U = real(U);
            self.result.Avg.T = real(T);
            self.result.Avg.C = real(C);
            self.result.Avg.runtime = runtime;
            if getOptions(self).verbose
                try
                    solvername = erase(self.result.solver,'Solver');
                catch
                    solvername = self.result.solver(7:end);
                end
                line_printf('\n%s analysis (method: %s) completed. Runtime: %f seconds.\n',solvername,self.result.Avg.method,runtime);
            end
        end
        
        function self = setDistribResults(self,Cd,runtime)
            % SELF = SETDISTRIBRESULTS(SELF,CD,RUNTIME)
            
            % Store distribution metrics at steady-state
            self.result.('solver') = getName(self);
            self.result.Distrib.('method') = getOptions(self).method;
            self.result.Distrib.C = Cd;
            self.result.Distrib.runtime = runtime;
        end
        
        function self = setTranProb(self,t,pi_t,SS,runtimet)
            % SELF = SETTRANPROB(SELF,T,PI_T,SS,RUNTIMET)
            
            % Store transient average metrics
            self.result.('solver') = getName(self);
            self.result.Tran.Prob.('method') = getOptions(self).method;
            self.result.Tran.Prob.t = t;
            self.result.Tran.Prob.pi_t = pi_t;
            self.result.Tran.Prob.SS = SS;
            self.result.Tran.Prob.runtime = runtimet;
        end
        
        function self = setTranAvgResults(self,Qt,Ut,Rt,Tt,Ct,Xt,runtimet)
            % SELF = SETTRANAVGRESULTS(SELF,QT,UT,RT,TT,CT,XT,RUNTIMET)
            
            % Store transient average metrics
            self.result.('solver') = getName(self);
            self.result.Tran.Avg.('method') = getOptions(self).method;
            for i=1:size(Qt,1), for r=1:size(Qt,2), if isnan(Qt{i,r}), Qt={}; end, end, end
            for i=1:size(Rt,1), for r=1:size(Rt,2), if isnan(Rt{i,r}), Rt={}; end, end, end
            for i=1:size(Ut,1), for r=1:size(Ut,2), if isnan(Ut{i,r}), Ut={}; end, end, end
            for i=1:size(Tt,1), for r=1:size(Tt,2), if isnan(Tt{i,r}), Tt={}; end, end, end
            for i=1:size(Xt,1), for r=1:size(Xt,2), if isnan(Xt{i,r}), Xt={}; end, end, end
            for i=1:size(Ct,1), for r=1:size(Ct,2), if isnan(Ct{i,r}), Ct={}; end, end, end
            self.result.Tran.Avg.Q = Qt;
            self.result.Tran.Avg.R = Rt;
            self.result.Tran.Avg.U = Ut;
            self.result.Tran.Avg.T = Tt;
            self.result.Tran.Avg.X = Xt;
            self.result.Tran.Avg.C = Ct;
            self.result.Tran.Avg.runtime = runtimet;
        end

    end

    methods 
        function dh = diff(self, handle, parameter)
            % dH = DIFF(H,P)
            %
            % Compute derivative of metric with handle H with respect to 
            % a parameter P.
            % H and P can also be cell arrays, in which case a cell array
            % is returned.
            
            line_error(mfilename,'diff is not supported by this solver.');
        end

        
        function [lNormConst] = getProbNormConstAggr(self)
            % [LNORMCONST] = GETPROBNORMCONST()
            
            % Return normalizing constant of state probabilities
            line_error(mfilename,'getProbNormConstAggr is not supported by this solver.');
        end
        
        function Pstate = getProb(self, node, state)
            % PSTATE = GETPROBSTATE(NODE, STATE)
            
            % Return marginal state probability for station ist state
            line_error(mfilename,'getProb is not supported by this solver.');
        end
        
        function Psysstate = getProbSys(self)
            % PSYSSTATE = GETPROBSYSSTATE()
            
            % Return joint state probability
            line_error(mfilename,'getProbSys is not supported by this solver.');
        end
        
        function Pnir = getProbAggr(self, node, state_a)
            % PNIR = GETPROBSTATEAGGR(NODE, STATE_A)
            
            % Return marginal state probability for station ist state
            line_error(mfilename,'getProbAggr is not supported by this solver.');
        end
        
        function Pnjoint = getProbSysAggr(self)
            % PNJOINT = GETPROBSYSSTATEAGGR()
            
            % Return joint state probability
            line_error(mfilename,'getProbSysAggr is not supported by this solver.');
        end
        
        function tstate = sample(self, node, numEvents)
            % TSTATE = SAMPLE(NODE, numEvents)
            
            % Return marginal state probability for station ist state
            line_error(mfilename,'sample is not supported by this solver.');
        end
        
        function tstate = sampleAggr(self, node, numEvents)
            % TSTATE = SAMPLEAGGR(NODE, numEvents)
            
            % Return marginal state probability for station ist state
            line_error(mfilename,'sampleAggr is not supported by this solver.');
        end
        
        function tstate = sampleSys(self, numEvents)
            % TSTATE = SAMPLESYS(numEvents)
            
            % Return joint state probability
            line_error(mfilename,'sampleSys is not supported by this solver.');
        end
        
        function tstate = sampleSysAggr(self, numEvents)
            % TSTATE = SAMPLESYSAGGR(numEvents)
            
            % Return joint state probability
            line_error(mfilename,'sampleSysAggr is not supported by this solver.');
        end
        
        function RD = getCdfRespT(self, R)
            % RD = GETCDFRESPT(R)
            
            % Return cumulative distribution of response times at steady-state
            line_error(mfilename,'getCdfRespT is not supported by this solver.');
        end
        
        function RD = getTranCdfRespT(self, R)
            % RD = GETTRANCDFRESPT(R)
            
            % Return cumulative distribution of response times during transient
            line_error(mfilename,'getTranCdfRespT is not supported by this solver.');
        end
        
        function RD = getCdfPassT(self, R)
            % RD = GETCDFPASST(R)
            
            % Return cumulative distribution of passage times at steady-state
            line_error(mfilename,'getCdfPassT is not supported by this solver.');
        end
        
        function RD = getTranCdfPassT(self, R)
            % RD = GETTRANCDFPASST(R)
            
            % Return cumulative distribution of passage times during transient
            line_error(mfilename,'getTranCdfPassT is not supported by this solver.');
        end
        
    end
    
    methods (Static)
        function solvers = getAllSolvers(model, options)
            % SOLVERS = GETALLSOLVERS(MODEL, OPTIONS)
            
            % Return a cell array with all Network solvers
            if nargin<2 %~exist('options','var')
                options = Solver.defaultOptions;
            end
            solvers = {};
            solvers{end+1} = SolverCTMC(model, options);
            solvers{end+1} = SolverJMT(model, options);
            solvers{end+1} = SolverSSA(model, options);
            solvers{end+1} = SolverFluid(model, options);
            solvers{end+1} = SolverMAM(model, options);
            solvers{end+1} = SolverMVA(model, options);
            solvers{end+1} = SolverNC(model, options);
        end
        
        function solvers = getAllFeasibleSolvers(model, options)
            % SOLVERS = GETALLFEASIBLESOLVERS(MODEL, OPTIONS)
            
            % Return a cell array with all Network solvers feasible for
            % this model
            if nargin<2 %~exist('options','var')
                options = Solver.defaultOptions;
            end
            solvers = {};
            if SolverCTMC.supports(model)
                solvers{end+1} = SolverCTMC(model, options);
            end
            if SolverJMT.supports(model)
                solvers{end+1} = SolverJMT(model, options);
            end
            if SolverSSA.supports(model)
                solvers{end+1} = SolverSSA(model, options);
            end
            if SolverFluid.supports(model)
                solvers{end+1} = SolverFluid(model, options);
            end
            if SolverGen.supports(model)
                solvers{end+1} = SolverGen(model, options);
            end
            if SolverMAM.supports(model)
                solvers{end+1} = SolverMAM(model, options);
            end
            if SolverMVA.supports(model)
                solvers{end+1} = SolverMVA(model, options);
            end
            if SolverNC.supports(model)
                solvers{end+1} = SolverNC(model, options);
            end
        end
        
    end
    
end
