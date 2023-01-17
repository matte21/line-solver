function [QN,UN,RN,TN,CN,XN,InfGen,StateSpace,StateSpaceAggr,EventFiltration,runtime,fname,sncopy] = solver_ctmc_analyzer(sn, options)
% [QN,UN,RN,TN,CN,XN,INFGEN,STATESPACE,STATESPACEAGGR,EVENTFILTRATION,RUNTIME,FNAME,sn] = SOLVER_CTMC_ANALYZER(sn, OPTIONS)
%
% Copyright (c) 2012-2023, Imperial College London
% All rights reserved.

%if options.remote
%    sn.rtfun = {};
%    sn.lst = {};
%    qn_json = jsonencode(sn);
%    sn = NetworkStruct.fromJSON(qn_json)
%return
%end

M = sn.nstations;    %number of stations
K = sn.nclasses;    %number of classes
S = sn.nservers;
NK = sn.njobs';  % initial population per class
schedid = sn.schedid;

Tstart = tic;
PH = sn.proc;

if any(sn.nodetype == NodeType.Cache)
    options.hide_immediate = false;
end

[InfGen,StateSpace,StateSpaceAggr,EventFiltration,arvRates,depRates,sn] = solver_ctmc(sn, options); % sn is updated with the state space

% if the initial state does not reflect the final state of the state
% vectors, attempt to correct it
for isf=1:sn.nstateful
    if size(sn.state{isf},2) < size(sn.space{isf},2)
        row = matchrow(sn.space{isf}(:,end-length(sn.state{isf})+1:end),sn.state{isf});
        if row > 0
            sn.state{isf} = sn.space{isf}(row,:);
        end
    end
end
sncopy = sn;

if options.keep
    fname = lineTempName;
    save([fname,'.mat'],'InfGen','StateSpace','StateSpaceAggr','EventFiltration')
    line_printf('\nCTMC infinitesimal generator and state space saved in: ');
    line_printf([fname, '.mat'])
else
    fname = '';
end

wset = 1:length(InfGen);

% for caches we keep the immediate transitions to give hit/miss rates
[probSysState, ~, nConnComp, connComp] = ctmc_solve(InfGen, options);

if any(isnan(probSysState))
    if nConnComp > 1
        % the matrix was reducible
        initState = matchrow(StateSpace, cell2mat(sn.state'));
        % determine the weakly connected component associated to the initial state
        wset = find(connComp == connComp(initState));
        probSysState = ctmc_solve(InfGen(wset, wset), options);
        InfGen = InfGen(wset, wset);
        StateSpace = StateSpace(wset,:);
    end
end

probSysState(probSysState<1e-14)=0;
probSysState = probSysState/sum(probSysState);

XN = NaN*zeros(1,K);
UN = NaN*zeros(M,K);
QN = NaN*zeros(M,K);
RN = NaN*zeros(M,K);
TN = NaN*zeros(M,K);
CN = NaN*zeros(1,K);

istSpaceShift = zeros(1,M);
for i=1:M
    if i==1
        istSpaceShift(i) = 0;
    else
        istSpaceShift(i) = istSpaceShift(i-1) + size(sn.space{i-1},2);
    end
end

for k=1:K
    refsf = sn.stationToStateful(sn.refstat(k));
    XN(k) = probSysState*arvRates(wset,refsf,k);
end

for i=1:M
    isf = sn.stationToStateful(i);
    for k=1:K
        TN(i,k) = probSysState*depRates(wset,isf,k);
        QN(i,k) = probSysState*StateSpaceAggr(wset,(i-1)*K+k);
    end
    switch schedid(i)
        case SchedStrategy.ID_INF
            for k=1:K
                UN(i,k) = QN(i,k);
            end
        case {SchedStrategy.ID_PS, SchedStrategy.ID_DPS, SchedStrategy.ID_GPS}
            if isempty(sn.lldscaling) && isempty(sn.cdscaling)
                for k=1:K
                    if ~isempty(PH{i}{k})
                        UN(i,k) = probSysState*arvRates(wset,isf,k)*map_mean(PH{i}{k})/S(i);
                    end
                end
            else % lld/cd cases
                ind = sn.stationToNode(i);
                UN(i,1:K) = 0;
                for st = wset
                    [ni,nir] = State.toMarginal(sn, ind, StateSpace(st,(istSpaceShift(i)+1):(istSpaceShift(i)+size(sn.space{i},2))));
                    if ni>0                        
                        for k=1:K
                            UN(i,k) = UN(i,k) + probSysState(st)*nir(k)*sn.schedparam(i,k)/(nir*sn.schedparam(i,:)');
                        end
                    end
                end
            end
        otherwise
            if isempty(sn.lldscaling) && isempty(sn.cdscaling)
                for k=1:K
                    if ~isempty(PH{i}{k})
                        UN(i,k) = probSysState*arvRates(wset,isf,k)*map_mean(PH{i}{k})/S(i);
                    end
                end
            else % lld/cd cases
                ind = sn.stationToNode(i);
                UN(i,1:K) = 0;
                for st = wset
                    [ni,~,sir] = State.toMarginal(sn, ind, StateSpace(st,(istSpaceShift(i)+1):(istSpaceShift(i)+size(sn.space{i},2))));
                    if ni>0
                        for k=1:K
                            UN(i,k) = UN(i,k) + probSysState(st)*sir(k)/S(i);
                        end
                    end
                end
            end
    end
end

for k=1:K
    for i=1:M
        if TN(i,k)>0
            RN(i,k) = QN(i,k)./TN(i,k);
        else
            RN(i,k)=0;
        end
    end
    CN(k) = NK(k)./XN(k);
end

QN(isnan(QN))=0;
CN(isnan(CN))=0;
RN(isnan(RN))=0;
UN(isnan(UN))=0;
XN(isnan(XN))=0;
TN(isnan(TN))=0;

runtime = toc(Tstart);

% now update the routing probabilities in nodes with state-dependent routing
TNcache = [];
for k=1:K
    for isf=1:sn.nstateful
        if sncopy.nodetype(isf) == NodeType.Cache
            TNcache(isf,k) = probSysState*depRates(wset,isf,k);
        end
    end
end

% updates cache actual hit and miss data
for k=1:K
    for isf=1:sncopy.nstateful
        if sncopy.nodetype(isf) == NodeType.Cache
            ind = sncopy.statefulToNode(isf);
            if length(sncopy.nodeparam{ind}.hitclass)>=k
                h = sncopy.nodeparam{ind}.hitclass(k);
                m = sncopy.nodeparam{ind}.missclass(k);
                if h> 0 && m > 0
                    sncopy.nodeparam{ind}.actualhitprob(k) = TNcache(isf,h)/sum(TNcache(isf,[h,m]));
                    sncopy.nodeparam{ind}.actualmissprob(k) = TNcache(isf,m)/sum(TNcache(isf,[h,m]));
                end
            end
        end
    end
end
end
