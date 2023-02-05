function [XN,UN,QN,RN,TN,CN,tranSysState,tranSync,snc]=solver_ssa_analyzer_spmd(sn, laboptions)
% [XN,UN,QN,RN,TN,CN]=SOLVER_SSA_ANALYZER_SPMD(LABOPTIONS, QN, PH)

snc = sn; % required due to spmn parallelism
M = snc.nstations;    %number of stations
K = snc.nclasses;    %number of classes
PH = sn.proc;
S = snc.nservers;
NK = snc.njobs';  % initial population per class

spmd
    laboptions.samples = ceil(laboptions.samples / numlabs);
    laboptions.verbose = false;
    switch laboptions.method
        case {'para','parallel'}
            [probSysState,SSq,arvRates,depRates,~,~,snc] = solver_ssa(snc, laboptions);
        case {'para.hash','parallel.hash'}
            [probSysState,SSq,arvRates,depRates,snc] = solver_ssa_hashed(snc, laboptions);
    end
    XN = NaN*zeros(1,K);
    UN = NaN*zeros(M,K);
    QN = NaN*zeros(M,K);
    RN = NaN*zeros(M,K);
    TN = NaN*zeros(M,K);
    CN = NaN*zeros(1,K);    
    for k=1:K
        refsf = snc.stationToStateful(snc.refstat(k));
        XN(k) = probSysState*depRates(:,refsf,k);
        for i=1:M
            isf = snc.stationToStateful(i);
            TN(i,k) = probSysState*depRates(:,isf,k);
            QN(i,k) = probSysState*SSq(:,(i-1)*K+k);
            switch snc.schedid(i)
                case SchedStrategy.ID_INF
                    UN(i,k) = QN(i,k);
                otherwise
                    % we use Little's law, otherwise there are issues in
                    % estimating the fraction of time assigned to class k (to
                    % recheck)
                    if ~isempty(PH{i}{k})
                        UN(i,k) = probSysState*arvRates(:,i,k)*map_mean(PH{i}{k})/S(i);
                    end
            end
        end
    end
    
    for k=1:K
        for i=1:M
            if TN(i,k)>0
                RN(i,k) = QN(i,k)./TN(i,k);
            else
                RN(i,k) = 0;
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
    
    % now update the routing probabilities in nodes with state-dependent routing
    for k=1:K
        for isf=1:snc.nstateful
            if snc.nodetype(isf) == NodeType.Cache
                TNcache(isf,k) = probSysState*depRates(:,isf,k);
            end
        end
    end
    
    % updates cache actual hit and miss data
    for k=1:K
        for isf=1:snc.nstateful
            if snc.nodetype(isf) == NodeType.Cache
                ind = snc.statefulToNode(isf);
                if length(snc.nodeparam{ind}.hitclass)>=k
                    h = snc.nodeparam{ind}.hitclass(k);
                    m = snc.nodeparam{ind}.missclass(k);
                    snc.nodeparam{ind}.actualhitprob(k) = TNcache(isf,h)/sum(TNcache(isf,[h,m]));
                    snc.nodeparam{ind}.actualmissprob(k) = TNcache(isf,m)/sum(TNcache(isf,[h,m]));
                end
            end
        end
    end
end

nLabs = length(QN);
QN = cellsum(QN)/nLabs;
UN = cellsum(UN)/nLabs;
RN = cellsum(RN)/nLabs;
TN = cellsum(TN)/nLabs;
CN = cellsum(CN)/nLabs;
XN = cellsum(XN)/nLabs;

for k=1:K
    for isf=1:sn.nstateful
        if sn.nodetype(isf) == NodeType.Cache
            ind = sn.statefulToNode(isf);
            sn.nodeparam{ind}.actualhitprob(k) = 0;
            sn.nodeparam{ind}.actualmissprob(k) = 0;
            for l=1:nLabs
                qntmp = snc{l};                
                if length(qntmp.nodeparam{ind}.hitclass)>=k                
                    sn.nodeparam{ind}.actualhitprob(k) = sn.nodeparam{ind}.actualhitprob(k) + (1/nLabs) * qntmp.nodeparam{ind}.actualhitprob(k);
                    sn.nodeparam{ind}.actualmissprob(k) = sn.nodeparam{ind}.actualmissprob(k) + (1/nLabs) * qntmp.nodeparam{ind}.actualmissprob(k);
                end
            end
        end
    end
end
snc = sn;
tranSysState=[];
tranSync=[];
end
