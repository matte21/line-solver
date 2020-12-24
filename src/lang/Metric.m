classdef Metric < Copyable
    % An output metric of a Solver, such as a performance index
    %
    % Copyright (c) 2012-2020, Imperial College London
    % All rights reserved.
    
    properties
        type;
        class;
        station;
        simConfInt;
        simMaxRelErr;
        disabled;
        transient;
    end
    
    properties (Hidden)
        stationIndex;
        classIndex;
        %nodeIndex;
    end
    
    methods (Hidden)
        %Constructor
        function self = Metric(type, class, station)
            % SELF = METRIC(TYPE, CLASS, STATION)
            
            self.type = type;
            self.class = class;
            if nargin > 2
                self.station = station;
            else
                self.station = '';
                self.station.name = '';
            end
            self.simConfInt = 0.99;
            self.simMaxRelErr = 0.03;
            self.disabled = 0;
            self.transient = false;
            
            %    self.nodeIndex = NaN;
            self.stationIndex = NaN;
            self.classIndex = NaN;
        end
    end
    
    methods
        function setTransient(self)
            self.transient = true;
            self.simConfInt = NaN;
            self.simMaxRelErr = NaN;
        end
        
        function setStationIndex(self, i)
            % SELF = SETSTATIONINDEX(INDEX)
            self.stationIndex = i;
        end
        
        function setClassIndex(self, r)
            % SELF = SETCLASSINDEX(INDEX)
            self.classIndex = r;
        end
        
        function self = setTran(self, bool)
            % SELF = SETTRAN(BOOL)
            
            self.transient = bool;
        end
        
        function bool = isTran(self)
            % BOOL = ISTRAN()
            
            bool = self.transient;
        end
        
        function bool = isDisabled(self)
            % BOOL = ISDISABLED()
            
            bool = self.disabled;
        end
        
        function self = disable(self)
            % SELF = DISABLE()
            
            self.disabled = 1;
        end
        
        function self = enable(self)
            % SELF = ENABLE()
            
            self.disabled = 0;
        end
        
        function value = get(self, results, model)
            % VALUE = GET(RESULTS, MODEL)
            
            if self.disabled == 1
                value = NaN;
                return
            end
            if isnan(self.stationIndex) || self.stationIndex < 0
                %stationnames = model.getStationNames();
                %self.stationIndex = findstring(stationnames,self.station.name);
                self.stationIndex = self.station.stationIndex;
            end
            i = self.stationIndex;
            if isnan(self.classIndex)
                %classnames = model.getClassNames();
                %self.classIndex = findstring(classnames,self.class.name);
                self.classIndex = self.class.index;
            end
            r = self.classIndex;
            
            switch results.solver
                case 'SolverJMT'
                    switch self.type
                        case MetricType.TranTput
                            %results.Tran.Avg.T{i,r}.Name = sprintf('Throughput (station %d, class %d)',i,r);
                            %results.Tran.Avg.T{i,r}.TimeInfo.Units = 'since initialization';
                            value = results.Tran.Avg.T{i,r};
                            return
                        case MetricType.TranUtil
                            %results.Tran.Avg.U{i,r}.Name = sprintf('Utilization (station %d, class %d)',i,r);
                            %results.Tran.Avg.U{i,r}.TimeInfo.Units = 'since initialization';
                            value = results.Tran.Avg.U{i,r};
                            return
                        case MetricType.TranQLen
                            %results.Tran.Avg.Q{i,r}.Name = sprintf('Queue Length (station %d, class %d)',i,r);
                            %results.Tran.Avg.Q{i,r}.TimeInfo.Units = 'since initialization';
                            value = results.Tran.Avg.Q{i,r};
                            return
                        case MetricType.TranRespT
                            %results.Tran.Avg.Q{i,r}.Name = sprintf('Queue Length (station %d, class %d)',i,r);
                            %results.Tran.Avg.Q{i,r}.TimeInfo.Units = 'since initialization';
                            value = results.Tran.Avg.R{i,r};
                            return
                    end
                    
                    for i=1:length(results.metric)
                        type = self.type;
                        switch self.type
                            case MetricType.TranQLen
                                type = MetricType.QLen;
                            case MetricType.TranUtil
                                type = MetricType.Util;
                            case MetricType.TranTput
                                type = MetricType.Tput;
                            case MetricType.TranRespT
                                type = MetricType.RespT;
                        end
                        if strcmp(results.metric{i}.class, self.class.name) && strcmp(results.metric{i}.measureType,type) && strcmp(results.metric{i}.station, self.station.name)
                            chainIdx = find(cellfun(@any,strfind(model.getStruct.classnames,self.class.name)));
                            %chain = model.getChains{chainIdx};
                            switch self.class.type
                                case 'closed'
                                    N = model.getNumberOfJobs();
                                    if results.metric{i}.analyzedSamples > sum(N(chainIdx)) % for a class to be considered recurrent we ask more samples than jobs in the corresponding closed chain
                                        value = results.metric{i}.meanValue;
                                    else
                                        value = 0; % transient metric, long term avg is 0
                                    end
                                case 'open'
                                    if results.metric{i}.analyzedSamples >= 0 % we assume that open classes are always recurrent
                                        value = results.metric{i}.meanValue;
                                    else
                                        value = 0; % transient metric, long term avg is 0
                                    end
                            end
                            break;
                        end
                    end
                otherwise % another LINE solver
                    if nargin<3 %~exist('model','var')
                        line_error(mfilename,'Wrong syntax, use Metric.get(results,model).\n');
                    end
                    if isnan(self.stationIndex)
                        %stationnames = model.getStationNames();
                        %self.stationIndex = findstring(stationnames,self.station.name);
                        self.stationIndex = self.station.stationIndex;
                    end
                    i = self.stationIndex;
                    if isnan(self.classIndex)
                        %classnames = model.getClassNames();
                        %self.classIndex = findstring(classnames,self.class.name);
                        self.classIndex = self.class.index;
                    end
                    r = self.classIndex;
                    switch self.type
                        case MetricType.Util
                            if isempty(results.Avg.U)
                                value = NaN;
                            else
                                value = results.Avg.U(i,r);
                            end
                        case MetricType.SysRespT
                            if isempty(results.Avg.C)
                                value = NaN;
                            else
                                value = results.Avg.C(i,r);
                            end
                        case MetricType.SysTput
                            if isempty(results.Avg.X)
                                value = NaN;
                            else
                                value = results.Avg.X(i,r);
                            end
                        case MetricType.RespT
                            if isempty(results.Avg.R)
                                value = NaN;
                            else
                                value = results.Avg.R(i,r);
                            end
                        case MetricType.Tput
                            if isempty(results.Avg.T)
                                value = NaN;
                            else
                                value = results.Avg.T(i,r);
                            end
                        case MetricType.QLen
                            if isempty(results.Avg.Q)
                                value = NaN;
                            else
                                value = results.Avg.Q(i,r);
                            end
                        case MetricType.TranTput
                            %results.Tran.Avg.T{i,r}.Name = sprintf('Throughput (station %d, class %d)',i,r);
                            %results.Tran.Avg.T{i,r}.TimeInfo.Units = 'since initialization';
                            if isempty(results.Tran.Avg.T)
                                value = NaN;
                            else
                                value = results.Tran.Avg.T{i,r};
                            end
                        case MetricType.TranUtil
                            %results.Tran.Avg.U{i,r}.Name = sprintf('Utilization (station %d, class %d)',i,r);
                            %results.Tran.Avg.U{i,r}.TimeInfo.Units = 'since initialization';
                            value = results.Tran.Avg.U{i,r};
                            if isempty(results.Tran.Avg.U)
                                value = NaN;
                            else
                                value = results.Tran.Avg.U{i,r};
                            end
                        case MetricType.TranQLen
                            %results.Tran.Avg.Q{i,r}.Name = sprintf('Queue Length (station %d, class %d)',i,r);
                            %results.Tran.Avg.Q{i,r}.TimeInfo.Units = 'since initialization';
                            value = results.Tran.Avg.Q{i,r};
                            if isempty(results.Tran.Avg.Q)
                                value = NaN;
                            else
                                value = results.Tran.Avg.Q{i,r};
                            end
                        case MetricType.TranRespT
                            %results.Tran.Avg.Q{i,r}.Name = sprintf('Queue Length (station %d, class %d)',i,r);
                            %results.Tran.Avg.Q{i,r}.TimeInfo.Units = 'since initialization';
                            value = results.Tran.Avg.R{i,r};
                            if isempty(results.Tran.Avg.R)
                                value = NaN;
                            else
                                value = results.Tran.Avg.R{i,r};
                            end
                    end
            end
        end
    end
end

