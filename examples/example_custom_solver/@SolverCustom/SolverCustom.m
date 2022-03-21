classdef SolverCustom < NetworkSolver
    % Example of custom solver
    %
    % Copyright (c) 2012-2022, Imperial College London
    % All rights reserved.
    
    methods
        function self = SolverCustom(model,varargin)
            % SELF = SOLVERCUSTOM(MODEL,VARARGIN)
            
            self@NetworkSolver(model, mfilename);
            self.setOptions(Solver.parseOptions(varargin, self.defaultOptions));
            if strcmp(self.getOptions.method,'default')
                line_error(mfilename,'Line:UnsupportedMethod','This solver does not have a default solution method. Used the method option to choose a solution technique.');
            end
        end
        
        runtime = run(self)
    end
    
    methods (Static)
        function featSupported = getFeatureSet()
            % FEATSUPPORTED = GETFEATURESET()
            
            featSupported = SolverFeatureSet;
            featSupported.setTrue({'Sink','Source','Queue',...
                'Cox2','Erlang','Exponential','HyperExp',...
                'Pareto','Weibull','Lognormal','Uniform','Det', ...
                'Buffer','Server','JobSink','RandomSource','ServiceTunnel',...
                'RoutingStrategy_PROB','RoutingStrategy_RAND',...
                'SchedStrategy_HOL','SchedStrategy_FCFS','OpenClass','Replayer'});
        end
        
        function [bool, featSupported] = supports(model)
            % [BOOL, FEATSUPPORTED] = SUPPORTS(MODEL)
            
            featUsed = model.getUsedLangFeatures();
            featSupported = SolverCustom.getFeatureSet();
            bool = SolverFeatureSet.supports(featSupported, featUsed);
        end
    end
    
    methods (Static)
        function options = defaultOptions()
            % OPTIONS = DEFAULTOPTIONS()
            
            options = Solver.defaultOptions();
            options.timespan = [Inf,Inf];
        end
    end
end