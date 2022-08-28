function [QNclass,UNclass,RNclass,TNclass,ANclass,WNclass] = getAvg(self,Q,U,R,T,A,W)
% [QNCLASS,UNCLASS,RNCLASS,TNCLASS,ANCLASS,WNCLASS] = GETAVG(SELF,Q,U,R,T,A,W)

% Return average station metrics at steady-state
%
% Copyright (c) 2012-2022, Imperial College London
% All rights reserved.

if ~isempty(self.model.obj)
    sn = self.model.getStruct;
    M = sn.nstations;
    R = sn.nclasses;
    AvgTable = self.obj.getAvgTable;
    [QN,UN,RN,~,TN] = JLINE.arrayListToResults(AvgTable);
    AN = 0*TN;
    WN = 0*RN;
    QNclass = reshape(QN,R,M)';
    UNclass = reshape(UN,R,M)';
    RNclass = reshape(RN,R,M)';
    TNclass = reshape(TN,R,M)';
    ANclass = reshape(AN,R,M)';
    WNclass = reshape(WN,R,M)';
    return
end

if nargin == 1 % no parameter
    if isempty(self.model.handles) || ~isfield(self.model.handles,'Q') || ~isfield(self.model.handles,'U') || ~isfield(self.model.handles,'R') || ~isfield(self.model.handles,'T') || ~isfield(self.model.handles,'A')
        resetResults(self); % reset in case there are partial results saved
    end
    [Q,U,R,T,A,W] = self.getAvgHandles;
elseif nargin == 2
    handlers = Q;
    Q=handlers{1};
    U=handlers{2};
    R=handlers{3};
    T=handlers{4};
    A=handlers{5};
    W=handlers{6};
end

if isfield(self.options,'timespan')
    if isfinite(self.options.timespan(2))
        line_error(mfilename,'The getAvg method does not support the timespan option, use the getTranAvg method instead.');
    end
else
    self.options.timespan = [0,Inf];
end

if ~self.hasAvgResults || ~self.options.cache
    try
        runAnalyzer(self);
    catch ME
        switch ME.identifier
            case {'Line:FeatureNotSupportedBySolver', 'Line:ModelTooLargeToSolve', 'Line:UnspecifiedOption'}
                if self.options.verbose
                    line_printf('\n%s',ME.message);
                end
                QNclass=[];
                UNclass=[];
                RNclass=[];
                TNclass=[];
                ANclass=[];
                WNclass=[];
                return
            otherwise
                rethrow(ME)
        end
    end
    if ~self.hasAvgResults
        line_error(mfilename,'Line is unable to return results for this model.');
    end
end % else return cached value

sn = self.getStruct();
M = sn.nstations;
K = sn.nclasses;
V = cellsum(sn.visits);

QNclass = [];
UNclass = [];
RNclass = [];
TNclass = [];
ANclass = [];
WNclass = [];

if ~isempty(Q)
    QNclass = zeros(M,K);
    for k=1:K
        for i=1:M
            if ~Q{i,k}.disabled && ~isempty(self.result.Avg.Q)
                QNclass(i,k) = self.result.Avg.Q(i,k);
            else
                QNclass(i,k) = NaN;
            end
        end
    end
end

if ~isempty(U)
    UNclass = zeros(M,K);
    for k=1:K
        for i=1:M
            if ~U{i,k}.disabled && ~isempty(self.result.Avg.U)
                UNclass(i,k) = self.result.Avg.U(i,k);
            else
                UNclass(i,k) = NaN;
            end
        end
    end
end

if ~isempty(R)
    RNclass = zeros(M,K);
    for k=1:K
        for i=1:M
            if ~R{i,k}.disabled && ~isempty(self.result.Avg.R)
                RNclass(i,k) =self.result.Avg.R(i,k);
            else
                RNclass(i,k) = NaN;
            end
        end
    end
end

if ~isempty(T)
    TNclass = zeros(M,K);
    for k=1:K
        for i=1:M
            if ~T{i,k}.disabled && ~isempty(self.result.Avg.T)
                TNclass(i,k) = self.result.Avg.T(i,k);
            else
                TNclass(i,k) = NaN;
            end
        end
    end
end

if ~isempty(A)
    ANclass = zeros(M,K);
    for k=1:K
        for i=1:M
            if ~A{i,k}.disabled && ~isempty(self.result.Avg.A)
                ANclass(i,k) = self.result.Avg.A(i,k);
            else
                ANclass(i,k) = NaN;
            end
        end
    end
end

%% nan values indicate that a metric is disabled
QNclass(isnan(QNclass))=0;
UNclass(isnan(UNclass))=0;
RNclass(isnan(RNclass))=0;
TNclass(isnan(TNclass))=0;
ANclass(isnan(ANclass))=0;
WNclass(isnan(WNclass))=0;

%% set to zero entries associated to immediate transitions
QNclass(RNclass < 10/Distrib.InfRate)=0;
UNclass(RNclass < 10/Distrib.InfRate)=0;
RNclass(RNclass < 10/Distrib.InfRate)=0;
WNclass(RNclass < 10/Distrib.InfRate)=0;

%% round to zero numerical perturbations
QNclass(QNclass < Distrib.Zero)=0;
UNclass(UNclass < Distrib.Zero)=0;
RNclass(RNclass < Distrib.Zero)=0;
ANclass(ANclass < Distrib.Zero)=0;
TNclass(TNclass < Distrib.Zero)=0;

WNclass = 0*RNclass;
for i=1:M
    for k=1:K
        if isempty(W) || W{i,k}.disabled
            WNclass(i,k) = NaN;
        else
            if ~isempty(RNclass) && RNclass(i,k)>0
                c = find(sn.chains(:,k));
                if RNclass(i,k) < Distrib.Zero
                    WNclass(i,k) = RNclass(i,k);
                else
                    refclass = sn.refclass(c);
                    if refclass>0
                        % if there is a reference class, use this
                        WNclass(i,k) = RNclass(i,k)*V(i,k)/sum(V(sn.refstat(k),refclass));
                    else
                        WNclass(i,k) = RNclass(i,k)*V(i,k)/sum(V(sn.refstat(k),sn.inchain{c}));
                    end
                end
            end
        end
    end
end

WNclass(isnan(WNclass))=0;
WNclass(WNclass < 10/Distrib.InfRate)=0;
WNclass(WNclass < Distrib.Zero)=0;

if ~isempty(UNclass)
    unstableQueues = find(sum(UNclass,2)>0.99 * sn.nservers);
    if any(unstableQueues) && any(isinf(sn.njobs))
        line_warning(mfilename,'The model has unstable queues, performance metrics may grow unbounded.')
    end
end
end