function [Q,U,R,T,A] = getAvgHandles(self)
% [Q,U,R,T,A] = GETAVGHANDLES()
% Get handles for mean performance metrics.
%
% Q(i,r): mean queue-length of class r at node i
% U(i,r): mean utilization of class r at node i
% R(i,r): mean response time of class r at node i (summed across visits)
% T(i,r): mean throughput of class r at node i
% A(i,r): mean arrival rate of class r at node i

% Copyright (c) 2012-2021, Imperial College London
% All rights reserved.
M = self.getNumberOfStations();
K = self.getNumberOfClasses();
classes = self.classes;
stations = self.stations;

isSource = false(M,1);
isSink = false(M,1);
hasServiceTunnel = false(M,1);
isServiceDefined = true(M,K);
for i=1:M
    isSource(i) = isa(stations{i},'Source');
    isSink(i) = isa(stations{i},'Sink');
    hasServiceTunnel(i) = strcmpi(class(stations{i}.server),'ServiceTunnel');
    if ~hasServiceTunnel(i)
        for r=1:K
            if isempty(stations{i}.server.serviceProcess{r}) || strcmpi(class(stations{i}.server.serviceProcess{r}{end}),'Disabled')
                isServiceDefined(i,r) = false;
            end
        end
    end
end

if isempty(self.handles) || ~isfield(self.handles,'Q')
    Q = cell(M,K); % queue-length
    for i=1:M
        for r=1:K
            Qir = Metric(MetricType.QLen, classes{r}, stations{i});
            if isSource(i)
                Qir.disable();
            end
            if isSink(i)
                Qir.disable();
            end
            if ~hasServiceTunnel(i)
                if ~isServiceDefined(i,r)
                    Qir.disable();
                end
            end
            Q{i,r} = Qir;
        end
    end
    self.addMetric(Q);
    self.handles.Q = Q;
else
    Q = self.handles.Q;
end

if isempty(self.handles) || ~isfield(self.handles,'U')
    M = self.getNumberOfStations();
    K = self.getNumberOfClasses();
    
    U = cell(M,1); % utilizations
    for i=1:M
        for r=1:K
            Uir = Metric(MetricType.Util, classes{r}, stations{i});
            if isSource(i)
                Uir.disable();
            end
            if isSink(i)
                Uir.disable();
            end
            if isa(stations{i},'Join') || isa(stations{i},'Fork')
                Uir.disable();
            end
            if ~hasServiceTunnel(i)
                if ~isServiceDefined(i,r)
                    Uir.disable();
                end
            end
            U{i,r} = Uir;
        end
    end
    self.addMetric(U);
    self.handles.U = U;
else
    U = self.handles.U;
end

if isempty(self.handles) || ~isfield(self.handles,'R')
    M = self.getNumberOfStations();
    K = self.getNumberOfClasses();
    
    R = cell(M,K); % response times
    for i=1:M
        for r=1:K
            Rir = Metric(MetricType.RespT, classes{r}, stations{i});
            if isSource(i)
                Rir.disable();
            end
            if isSink(i)
                Rir.disable();
            end
            if ~hasServiceTunnel(i)
                if ~isServiceDefined(i,r)
                    Rir.disable();
                end
            end
            R{i,r} = Rir;
        end
    end
    self.addMetric(R);
    self.handles.R = R;
else
    R = self.handles.R;
end

if isempty(self.handles) || ~isfield(self.handles,'T')
    M = self.getNumberOfStations();
    K = self.getNumberOfClasses();
    
    T = cell(1,K); % throughputs
    for i=1:M
        for r=1:K
            Tir = Metric(MetricType.Tput, classes{r}, stations{i});
            if ~hasServiceTunnel(i)
                if ~isServiceDefined(i,r)
                    Tir.disable();
                end
            end
            T{i,r} = Tir;
        end
    end
    self.addMetric(T);
    self.handles.T = T;
else
    T = self.handles.T;
end

if isempty(self.handles) || ~isfield(self.handles,'A')
    M = self.getNumberOfStations();
    K = self.getNumberOfClasses();
    
    A = cell(1,K); % arrival rate
    for i=1:M
        for r=1:K
            Air = Metric(MetricType.ArvR, classes{r}, stations{i});
            %self.addMetric(A{i,r}); % not supported by JMT
            if ~hasServiceTunnel(i)
                if ~isServiceDefined(i,r)
                    Air.disable();
                end
            end
            A{i,r} = Air;
        end
    end
    self.handles.A = A;
else
    A = self.handles.A;
end

end