classdef EnsembleSolver < Solver
    % Abstract class for solvers applicable to Ensemble models
    %
    % Copyright (c) 2012-2020, Imperial College London
    % All rights reserved.
    
    properties
        ensemble;
        solvers;
        results;
    end
    
    methods (Hidden)
        function self = EnsembleSolver(ensmodel, name, options)
            % SELF = ENSEMBLESOLVER(MODEL, NAME, OPTIONS)
            
            self@Solver(ensmodel, name);
            if exist('options','var')
                self.setOptions(options);
            else
                self.setOptions(EnsembleSolver.defaultOptions);
            end
            %self.ensemble = ensmodel.getEnsemble;
            self.solvers = {};
        end
    end
    
    methods %(Abstract) % implemented with errors for Octave compatibility
        function bool = supports(self, model) % true if model is supported by the solver
            % BOOL = SUPPORTS(MODEL) % TRUE IF MODEL IS SUPPORTED BY THE SOLVER
            
            error('Line:AbstractMethodCall','An abstract method was called. The function needs to be overridden by a subclass.');
            
        end
        
        function [QN,UN,RT,TT] = getAvg(self)
            % [QN,UN,RT,TT] = GETAVG()
            
            error('Line:AbstractMethodCall','An abstract method was called. The function needs to be overridden by a subclass.');
            
        end
        
        function init(self) % operations before starting to iterate
            % INIT() % OPERATIONS BEFORE STARTING TO ITERATE
            
            error('Line:AbstractMethodCall','An abstract method was called. The function needs to be overridden by a subclass.');
            
        end
        
        function pre(self, it) % operations before an iteration
            % PRE(IT) % OPERATIONS BEFORE AN ITERATION
            
            error('Line:AbstractMethodCall','An abstract method was called. The function needs to be overridden by a subclass.');
            
        end
        
        function [results, runtime] = analyze(self, e) % operations within an iteration
            % [RESULTS, RUNTIME] = ANALYZE(E) % OPERATIONS WITHIN AN ITERATION
            
            error('Line:AbstractMethodCall','An abstract method was called. The function needs to be overridden by a subclass.');
            
        end
        
        function post(self, it) % operations after an iteration
            % POST(IT) % OPERATIONS AFTER AN ITERATION
            
            error('Line:AbstractMethodCall','An abstract method was called. The function needs to be overridden by a subclass.');
            
        end
        
        function finish(self) % operations after interations are completed
            % FINISH() % OPERATIONS AFTER INTERATIONS ARE COMPLETED
            error('Line:AbstractMethodCall','An abstract method was called. The function needs to be overridden by a subclass.');
            
        end
        
        function bool = converged(self, it) % convergence test at iteration it
            % BOOL = CONVERGED(IT) % CONVERGENCE TEST AT ITERATION IT
            
            error('Line:AbstractMethodCall','An abstract method was called. The function needs to be overridden by a subclass.');
            
        end
    end
    
    methods % default implementations
        function submodels = list(self, it)
            % SUBMODELS = LIST(IT)
            
            % submodels to be considered at iteration it
            submodels = 1:self.getNumberOfModels;
        end
        
        function it = getIteration(self)
            % IT = GETITERATION()
            
            it = size(results,1);
        end
    end
    
    methods
        function solver = getSolver(self, e) % solver for ensemble model e
            % SOLVER = GETSOLVER(E) % SOLVER FOR ENSEMBLE MODEL E
            
            solver = self.solvers{e};
        end
        
        % setSolver(solvers) : solver cell array is stored as such
        % setSolver(solver) : solver is assigned to all stages
        % setSolver(solver, e) : solver is assigned to stage e
        function solver = setSolver(self, solver, e)
            % SOLVER = SETSOLVER(SOLVER, E)
            %solver.options.verbose = self.options.verbose;
            if iscell(solver)
                self.solvers = solver;
            else
                if ~exist('e','var')
                    for e=1:self.getNumberOfModels
                        self.solvers{e} = solver;
                    end
                else
                    self.solvers{e} = solver;
                end
            end
        end
        
        function E = getNumberOfModels(self)
            % E = GETNUMBEROFMODELS()
            
            E = length(self.ensemble);
        end
        
        function [runtime, sruntime, results] = run(self)
            % [RUNTIME, SRUNTIME, RESULTS] = RUN()
            T0 = tic;
            it = 0;
            options = self.options;
            E = self.getNumberOfModels();
            results = cell(1,E);
            sruntime = zeros(1,E); % solver runtimes
            self.init();
            % nearly identical, but parfor based
            while ~self.converged(it) && it < options.iter_max
                it = it + 1;
                self.pre(it);
                sruntime(it,1:E) = 0;
                T0=tic;
                switch options.method
                    case {'default','serial'}
                        for e = self.list(it)
                            [results{it,e}, solverTime] = self.analyze(it,e);
                            sruntime(it,e) = sruntime(it,e) + solverTime;
                        end
                    case {'para'}
                        parfor e = self.list(it)
                            [results{it,e}, solverTime] = self.analyze(it,e);
                            sruntime(it,e) = sruntime(it,e) + solverTime;
                        end
                end
                self.results = results;
                if options.verbose
                    Tpproc=toc(T0);
                    if it>1
                        fprintf('\nIter %d. ',it);
                    else
                        fprintf('Iter %d. ',it);
                    end
                    fprintf('Runtime: %f seconds.',Tpproc);
                    T0=tic;
                    fprintf(' Postprocessing: ');
                end
                self.post(it);
                Tpproc=toc(T0);
                if options.verbose
                    fprintf('%f seconds. ',Tpproc);
                end
            end
            self.finish();
            runtime = toc(T0);
        end       
    end
    
    methods (Static)
        % ensemble solver options
        function options = defaultOptions()
            % OPTIONS = DEFAULTOPTIONS()
            options = lineDefaults('Ensemble');
        end
    end
end
