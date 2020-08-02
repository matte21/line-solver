classdef LayeredNetworkSolver < Solver
    % Abstract class for solvers applicable to LayeredNetwork models
    %
    % Copyright (c) 2012-2020, Imperial College London
    % All rights reserved.
    
    properties
    end
    
    methods (Hidden)
        function self = LayeredNetworkSolver(model, name, options)
            % SELF = LAYEREDNETWORKSOLVER(MODEL, NAME, OPTIONS)
            self@Solver(model,name);
            if exist('options','var'), self.setOptions(options); end
            if ~isa(model,'LayeredNetwork')
                error('Model is not a LayeredNetwork.');
            end
        end
    end
    
    methods %(Abstract) % implemented with errors for Octave compatibility
        function bool = supports(self, model) % true if model is supported by the solver
            % BOOL = SUPPORTS(MODEL) % TRUE IF MODEL IS SUPPORTED BY THE SOLVER
            error('Line:AbstractMethodCall','An abstract method was called. The function needs to be overridden by a subclass.');
        end
        function [QN,UN,RN,TN] = getAvg(self)
            % [QN,UN,RN,TN] = GETAVG()
            error('Line:AbstractMethodCall','An abstract method was called. The function needs to be overridden by a subclass.');
        end
    end
    
    methods
        function [AvgTable,QT,UT,RT,TT] = getAvgTable(self, wantLQNSnaming)
            % [AVGTABLE,QT,UT,RT,TT] = GETAVGTABLE(WANTLQNSNAMING)
            if ~exist('wantLQNSnaming','var')
                wantLQNSnaming = false;
            end
            [QN,UN,RN,TN] = self.getAvg();
            Node = categorical(self.model.lqnGraph.Nodes.Node);
            Objects = self.model.lqnGraph.Nodes.Object;
            O = length(Objects);
            NodeType = categorical(O,1);
            for o = 1:O
                NodeType(o,1) = categorical({class(Objects{o})});
            end            
            if wantLQNSnaming
                Utilization = QN;
                QT = Table(Node,Utilization);
                ProcUtilization = UN;
                UT = Table(Node,ProcUtilization);
                Phase1ServiceTime = RN;
                RT = Table(Node,Phase1ServiceTime);
                Throughput = TN;
                TT = Table(Node,Throughput);
                AvgTable = Table(Node, NodeType, Utilization, ProcUtilization,...
                    Phase1ServiceTime, Throughput);
            else
                QLen = QN;
                QT = Table(Node,QLen);
                Util = UN;
                UT = Table(Node,Util);
                RespT = RN;
                RT = Table(Node,RespT);
                Tput = TN;
                TT = Table(Node,Tput);
                AvgTable = Table(Node, NodeType, QLen, Util, RespT, Tput);
            end
        end
    end
    
    methods (Static)
        % ensemble solver options
        function options = defaultOptions()
            % OPTIONS = DEFAULTOPTIONS()
            options = struct();
            options.method = 'default';
            options.init_sol = [];
            options.iter_max = 100;
            options.iter_tol = 1e-4;
            options.tol = 1e-4;
            options.verbose = 0;
        end
    end
end
