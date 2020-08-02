classdef SolverAuto < NetworkSolver
    % A solver that selects the solution method based on the model characteristics.
    %
    % Copyright (c) 2012-2020, Imperial College London
    % All rights reserved.
    
    
    properties
        candidates; % feasible solvers
    end
    
    methods
        %Constructor
        function self = SolverAuto(model, varargin)
            % SELF = SOLVERAUTO(MODEL, VARARGIN)
            
            self@NetworkSolver(model, mfilename);
            self.setOptions(Solver.parseOptions(varargin, self.defaultOptions));
            
            % solvers sorted from fastest to slowest
            solvers = {SolverMAM(model), SolverMVA(model), SolverNC(model), SolverFluid(model), SolverJMT(model), SolverSSA(model), SolverCTMC(model)};
            wstatus = warning('query');
            %warning off;
            boolSolver = [];
            for s=1:length(solvers)
                boolSolver(s) = solvers{s}.supports(self.model);
            end
            self.candidates = {solvers{find(boolSolver)}};
            warning(wstatus);
        end
    end
    
    methods
        function bool = supports(self, model)
            % BOOL = SUPPORTS(MODEL)
            
            if isempty(self.candidates)
                bool = false;
            else
                bool = true;
            end
        end
        
        function runtime = run(self, options) % generic method to run the solver
            % RUNTIME = RUN()
            % Run the solver % GENERIC METHOD TO RUN THE SOLVER
            
            T0 = tic;
            runtime = toc(T0);
        end
        
        function [QN,UN,RN,TN] = getAvg(self,Q,U,R,T)
            % [QN,UN,RN,TN] = GETAVG(SELF,Q,U,R,T)
            if nargin ==1
                [Q,U,R,T] = self.model.getAvgHandles;
            elseif nargin == 2
                handlers = Q;
                Q=handlers{1};
                U=handlers{2};
                R=handlers{3};
                T=handlers{4};
            end
                
            % first try with chosen solver, if the method is not available
            % or fails keep going with the other candidates
            proposedSolvers = {self.chooseSolver(), self.candidates{:}};
            for s=1:length(proposedSolvers)
                try
                    [QN,UN,RN,TN] = proposedSolvers{s}.getAvg(Q,U,R,T);
                    return
                end
            end
        end
        
        function [QNc,UNc,RNc,TNc] = getAvgChain(self,Q,U,R,T)
            % [QNC,UNC,RNC,TNC] = GETAVGCHAIN(SELF,Q,U,R,T)
            
            proposedSolvers = {self.chooseSolver(), self.candidates};
            for s=1:length(proposedSolvers)
                try
                    [QNc,UNc,RNc,TNc] = proposedSolvers{s}.getAvgChain(Q,U,R,T);
                    return
                end
            end
        end
        
        function [CNc,XNc] = getAvgSys(self,R,T)
            % [CNC,XNC] = GETAVGSYS(SELF,R,T)
            
            proposedSolvers = {self.chooseSolver(), self.candidates};
            for s=1:length(proposedSolvers)
                try
                    [CNc,XNc] = proposedSolvers{s}.getAvgSys(R,T);
                    return
                end
            end
        end
        
        function [QNt,UNt,TNt] = getTranAvg(self,Qt,Ut,Tt)
            % [QNT,UNT,TNT] = GETTRANAVG(SELF,QT,UT,TT)
            
            proposedSolvers = {self.chooseSolver(), self.candidates};
            for s=1:length(proposedSolvers)
                try
                    [QNt,UNt,TNt] = proposedSolvers{s}.getTranAvg(Qt,Ut,Tt);
                    return
                end
            end
        end
        
        % chooseStatic: choses a solver from static properties of the model
        function solver = chooseSolver(self)
            % SOLVER = CHOOSESOLVER()
            
            model = self.model;
            ncoptions = self.options;
            if model.hasProductFormSolution
                if model.hasSingleChain
                    %ncoptions = SolverNC.defaultOptions; 
                    ncoptions.method = 'exact';
                    solver = SolverNC(model, ncoptions);
                else % MultiChain
                    if model.hasHomogeneousScheduling(SchedStrategy.INF)
                        solver = SolverMVA(model);
                    elseif model.hasMultiServer
                        if sum(model.getNumberOfJobs) / sum(model.getNumberOfChains) > 30 % likely fluid regime
                            solver = SolverFluid(model);
                        elseif sum(model.getNumberOfJobs) / sum(model.getNumberOfChains) > 10 % mid/heavy load
                            solver = SolverMVA(model);
                        elseif sum(model.getNumberOfJobs) < 5 % light load
                            %ncoptions = SolverNC.defaultOptions; 
                            ncoptions.method = 'exact';
                            solver = SolverNC(model, ncoptions);
                        else
                            solver = SolverMVA(model);
                        end
                    else % product-form, no infinite servers
                        solver = SolverNC(model);
                    end
                end
            else
                solver = self.candidates{1}; % take fastest
            end
        end
    end
end
