classdef SolverFeatureSet < handle
    % An auxiliary class to specify the features supported by a solver.
    %
    % Copyright (c) 2012-2022, Imperial College London
    % All rights reserved.
    
    properties
        list; % list of features
    end
    
    properties (Constant)
        fields = {'ClassSwitch',...
            'Cache', ...
            'DelayStation',...
            'Fork',...
            'Join',...
            'Logger',...
            'Place', ...
            'Queue', ...
            'Sink',...
            'Source',...
            'Router',...
            'Transition', ...
            'Cox2',...
            'APH',...
            'Det', ...
            'Erlang',...
            'Exponential',...
            'Gamma',...
            'HyperExp', ...
            'Lognormal',...
            'MAP',...
            'MMPP2',...
            'Normal',...
            'Pareto',...
            'PH',...
            'Replayer',...
            'Uniform', ...
            'Weibull',...
            'StatelessClassSwitcher',...
            'CacheClassSwitcher',...
            'InfiniteServer',...
            'Forker',...
            'Joiner',...
            'LogTunnel', ...
            'SharedServer', ...
            'Buffer', ...
            'Linkage',...
            'Enabling', ...
            'Timing', ...
            'Firing', ...
            'Storage', ...
            'Timing', ...
            'RandomSource', ...
            'Dispatcher', ...
            'Server', ...
            'ServiceTunnel', ...
            'RoutingStrategy_PROB', ...
            'RoutingStrategy_RAND', ...
            'RoutingStrategy_RROBIN', ...
            'RoutingStrategy_WRROBIN', ...
            'RoutingStrategy_KCHOICES', ...
            'SchedStrategy_INF', ...
            'SchedStrategy_FCFS', ...
            'SchedStrategy_LCFS', ...
            'SchedStrategy_LCFSPR', ...
            'SchedStrategy_SEPT', ...
            'SchedStrategy_LEPT', ...
            'SchedStrategy_DPS', ...
            'SchedStrategy_GPS', ...
            'SchedStrategy_LJF', ...
            'SchedStrategy_SJF', ...
            'SchedStrategy_PS', ...
            'SchedStrategy_SIRO', ...
            'SchedStrategy_HOL', ...
            'SchedStrategy_EXT', ...
            'ClosedClass', ...
            'OpenClass'};
        % High-level properties
        %             self.list.('FiniteCapacity')=false;
        %             self.list.('Tandem')=false;
        %             self.list.('Cyclic')=false;
        %             self.list.('Multichain')=false;
        %             self.list.('Multiclass')=false;
        %             self.list.('Analysis_Avg')=false;
        %             self.list.('Analysis_Tran')=false;
        %             self.list.('Analysis_Distribution')=false;
        %             self.list.('Analysis_State')=false;
        %             self.list.('Method_Exact')=false;
        %             self.list.('Method_Simulation')=false;
    end
    
    methods
        function self = SolverFeatureSet()
            % SELF = SOLVERFEATURESET()
            
            % Nodes and Stations
            fields = SolverFeatureSet.fields;
            for f=1:length(fields)
                self.list.(fields{f})=false;
            end
        end
        
        function self = setTrue(self, feature)
            % SELF = SETTRUE(FEATURE)
            
            if iscell(feature)
                for c=1:length(feature)
                    self.setTrue(feature{c});
                end
            else
                if ~strcmpi(feature,'char') % ignore empty sections
                    self.list.(feature) = true;
                end
            end
        end
        
        function self = setFalse(self, feature)
            % SELF = SETFALSE(FEATURE)
            
            if iscell(feature)
                for c=1:length(feature)
                    self.setFalse(feature{c});
                end
            else
                self.list.(feature) = false;
            end
        end
        
    end
    
    methods(Static)
        function bool = supports(featSupportedList, featUsedList)
            % BOOL = SUPPORTS(FEATSUPPORTEDLIST, FEATUSEDLIST)
            
            bool = true;
            unsupported = {};
            
            % Nodes and Stations
            fields = SolverFeatureSet.fields;
            for f=1:length(fields)
                if featUsedList.list.(fields{f}) > featSupportedList.list.(fields{f})
                    bool = false;
                    unsupported{end+1} = fields{f}; %#ok<AGROW>
                end
            end
            
            if ~isempty(unsupported)
                str='Some features are not supported by the chosen solver (feature: ';
                for u=1:length(unsupported)
                    if u==1
                        str = sprintf('%s%s',str,unsupported{u});
                    else
                        str = sprintf('%s, %s',str,unsupported{u});
                    end
                end
                str = sprintf('%s).',str);
                line_warning(mfilename,str);
            end
        end
    end
end
