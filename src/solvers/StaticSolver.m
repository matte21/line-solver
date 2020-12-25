classdef StaticSolver < NetworkSolver
    % A fast static solver derived from a regular NetworkSolver
    %
    % Copyright (c) 2012-2021, Imperial College London
    % All rights reserved.
    
    properties (GetAccess = 'private', SetAccess='private')
    end
    
    properties (Access=protected)
    end
    
    properties (Hidden)
        qn;
    end
    
    properties
        analyzer;
        runtime;
    end
    
    % PUBLIC METHODS
    methods (Access=public)
        
        %Constructor
        function self = StaticSolver(solver)
            % SELF = NETWORK(MODELNAME)
            self@NetworkSolver(solver.getModel, [solver.getName,'.static'], solver.getOptions);
            self.qn = self.model.getStruct;
            [self.runtime, self.analyzer] = solver.runAnalysis();
        end
        
        function [runtime, analyzer] = runAnalysis(self, options, config)            
            T0=tic;
            if nargin<2
                options = self.getOptions;
            end
            if nargin<3
                config = [];
            end            
            Solver.resetRandomGeneratorSeed(options.seed);
            [QN,UN,RN,TN,CN,XN,runtime] = self.analyzer(self.qn);
            runtime = toc(T0);
            self.setAvgResults(QN,UN,RN,TN,CN,XN,runtime,options.method);
            analyzer = self.analyzer;
        end
        
    end
end
