function [QN,UN,RN,TN,CN,XN,InfGen,StateSpace,StateSpaceAggr,EventFiltration,runtime,fname,qnc] = solver_ctmc_analyzer(sn, options)
% [QN,UN,RN,TN,CN,XN,INFGEN,STATESPACE,STATESPACEAGGR,EVENTFILTRATION,RUNTIME,FNAME,sn] = SOLVER_CTMC_ANALYZER(sn, OPTIONS)
%
% Copyright (c) 2012-2021, Imperial College London
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
rt = sn.rt;
S = sn.nservers;
NK = sn.njobs';  % initial population per class
schedid = sn.schedid;

Tstart = tic;
PH = sn.proc;

myP = cell(K,K);
for k = 1:K
    for c = 1:K
        myP{k,c} = zeros(M);
    end
end

for i=1:M
    for j=1:M
        for k = 1:K
            for c = 1:K
                % routing table for each class
                myP{k,c}(i,j) = rt((i-1)*K+k,(j-1)*K+c);
            end
        end
    end
end

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
qnc = sn;

if options.keep
    fname = tempname;
    save([fname,'.mat'],'InfGen','StateSpace','StateSpaceAggr','EventFiltration')
    line_printf('\nCTMC infinitesimal generator and state space saved in: ');
    line_printf([fname, '.mat'])
else
    fname = '';
end

wset = 1:length(InfGen);

% for caches we keep the immediate transitions to give hit/miss rates
[pi, ~, nConnComp, connComp] = ctmc_solve(InfGen, options);

if any(isnan(pi))
    if nConnComp > 1
        % the matrix was reducible
        initState = matchrow(StateSpace, cell2mat(sn.state'));
        % determine the weakly connected component associated to the initial state
        wset = find(connComp == connComp(initState));
        pi = ctmc_solve(InfGen(wset, wset), options);
        InfGen = InfGen(wset, wset);
        StateSpace = StateSpace(wset,:);
    end
end

pi(pi<1e-14)=0;
pi = pi/sum(pi);

XN = NaN*zeros(1,K);
UN = NaN*zeros(M,K);
QN = NaN*zeros(M,K);
RN = NaN*zeros(M,K);
TN = NaN*zeros(M,K);
CN = NaN*zeros(1,K);


for k=1:K
    refsf = sn.stationToStateful(sn.refstat(k));
    XN(k) = pi*arvRates(wset,refsf,k);
    for i=1:M
        isf = sn.stationToStateful(i);
        TN(i,k) = pi*depRates(wset,isf,k);
        QN(i,k) = pi*StateSpaceAggr(wset,(i-1)*K+k);       
        switch schedid(i)
            case SchedStrategy.ID_INF
                UN(i,k) = QN(i,k);
            otherwise
                if ~isempty(PH{i}{k})
                    UN(i,k) = pi*arvRates(wset,isf,k)*map_mean(PH{i}{k})/S(i);
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
for k=1:K
    for isf=1:sn.nstateful
        if sn.nodetype(isf) == NodeType.Cache            
            TNcache(isf,k) = pi*depRates(wset,isf,k);
        end
    end
end

% updates cache actual hit and miss data
for k=1:K
    for isf=1:qnc.nstateful
        if qnc.nodetype(isf) == NodeType.Cache
            ind = qnc.statefulToNode(isf);
            if length(qnc.varsparam{ind}.hitclass)>=k
                h = qnc.varsparam{ind}.hitclass(k);
                m = qnc.varsparam{ind}.missclass(k);
                qnc.varsparam{ind}.actualhitprob(k) = TNcache(isf,h)/sum(TNcache(isf,[h,m]));
                qnc.varsparam{ind}.actualmissprob(k) = TNcache(isf,m)/sum(TNcache(isf,[h,m]));
            end
        end
    end
end
end
