function [QN,UN,RN,TN,CN,XN] = solver_qna(sn, options)
% [Q,U,R,T,C,X] = SOLVER_QNA(QN, OPTIONS)

% Copyright (c) 2012-2022, Imperial College London
% All rights reserved.

% Implementation as per Section 7.2.3 of N. Gautaum, Analysis of Queues, CRC Press, 2012.

config = options.config;
config.space_max = 1;

K = sn.nclasses;
rt = sn.rt;
S = 1./sn.rates;
scv = sn.scv; scv(isnan(scv))=0;

%% immediate feedback elimination
% this is adapted for class-switching, an alternative implementation would
% rescale by sum(rt((i-1)*K+r,(i-1)*K+1:R)) rather than rt((i-1)*K+r,(i-1)*K+r)
for i=1:size(rt,1)
    for r=1:K
        for j=1:size(rt,2)
            for s=1:K
                if i~=j
                    rt((i-1)*K+r, (j-1)*K+s) = rt((i-1)*K+r, (j-1)*K+s) / (1-rt((i-1)*K+r,(i-1)*K+r));
                end
            end
        end
        S(i,r) = S(i,r) / (1-rt((i-1)*K+r,(i-1)*K+r));
        scv(i,r) = rt((i-1)*K+r,(i-1)*K+r) + (1-rt((i-1)*K+r,(i-1)*K+r))*scv(i,r);
        rt((i-1)*K+r,(i-1)*K+r) = 0;
    end
end

%% generate local state spaces
I = sn.nnodes;
M = sn.nstations;
C = sn.nchains;
V = cellsum(sn.visits);
QN = zeros(M,K);
QN_1 = QN+Inf;

UN = zeros(M,K);
RN = zeros(M,K);
TN = zeros(M,K);
XN = zeros(1,K);

lambda = zeros(1,C);

it = 0;

if any(isfinite(sn.njobs))
%    line_error(mfilename,'QNA does not support closed classes.');
end

%isMixed = isOpen & isClosed;
%if isMixed
% treat open as having higher priority than closed
%sn.classprio(~isfinite(sn.njobs)) = 1 + max(sn.classprio(isfinite(sn.njobs)));
%end

%% compute departure process at source
a1 = zeros(M,K);
a2 = zeros(M,K);
d2 = zeros(M,1);
f2 = zeros(M*K,M*K); % scv of each flow pair (i,r) -> (j,s)
    for i=1:M
        for j=1:M
            if sn.nodetype(sn.stationToNode(j)) ~= NodeType.Source
                for r=1:K
                    for s=1:K
                        if rt((i-1)*K+r, (j-1)*K+s)>0
                            f2((i-1)*K+r, (j-1)*K+s) = 1; % C^2ij,r
                        end
                    end
                end
            end
        end
    end   
lambdas_inchain = cell(1,C);
scvs_inchain = cell(1,C);
d2c = [];
for c=1:C
    inchain = sn.inchain{c};
    sourceIdx = sn.refstat(inchain(1));
    lambdas_inchain{c} = sn.rates(sourceIdx,inchain);
    scvs_inchain{c} = scv(sourceIdx,inchain);
    lambda(c) = sum(lambdas_inchain{c}(isfinite(lambdas_inchain{c})));
    d2c(c) = qna_superpos(lambdas_inchain{c},scvs_inchain{c});
    if isinf(sum(sn.njobs(inchain))) % if open chain
        TN(sourceIdx,inchain') = lambdas_inchain{c};
    end
end
d2(sourceIdx)=d2c(sourceIdx,:)*lambda'/sum(lambda);

%% main iteration

while nanmax(nanmax(abs(QN-QN_1))) > Distrib.Tol && it <= options.iter_max %#ok<NANMAX>
    it = it + 1;
    QN_1 = QN;

    % update throughputs at all stations
    if it==1
        for c=1:C
            inchain = sn.inchain{c};
            for m=1:M
                TN(m,inchain) = V(m,inchain) .* lambda(c);
            end
        end
    end

    % superposition
    for i=1:M
        a1(i,:) = 0;
        a2(i,:) = 0;
        lambda_i = sum(TN(i,:));        
        for j=1:M
            for r=1:K
                for s=1:K
                    a1(i,r) = a1(i,r) + TN(j,s)*rt((j-1)*K+s, (i-1)*K+r);
                    a2(i,r) = a2(i,r) + (1/lambda_i) * f2((j-1)*K+s, (i-1)*K+r)*TN(j,s)*rt((j-1)*K+s, (i-1)*K+r);
                end
            end
        end
    end

    % update flow trhough queueing station
    for ind=1:I
        if sn.isstation(ind)
            ist = sn.nodeToStation(ind);
            switch sn.nodetype(ind)
                case NodeType.Join
                    % no-op
                    %                     for c=1:C
                    %                         inchain = sn.inchain{c};
                    %                         for k=inchain
                    %                             fanin = nnz(sn.rtnodes(:, (ind-1)*K+k));
                    %                             TN(ist,k) = lambda(c)*V(ist,k)/fanin;
                    %                             UN(ist,k) = 0;
                    %                             QN(ist,k) = 0;
                    %                             RN(ist,k) = 0;
                    %                         end
                    %                     end
                otherwise
                    switch sn.schedid(ist)
                        case SchedStrategy.ID_INF
                            for i=1:M
                                for r=1:K
                                    for s=1:K
                                        d2(ist,s) = a2(ist,s);
                                    end
                                end
                            end
                            for c=1:C
                                inchain = sn.inchain{c};
                                for k=inchain
                                    TN(ist,k) = a1(ist,k);
                                    UN(ist,k) = S(ist,k)*TN(ist,k);
                                    QN(ist,k) = TN(ist,k).*S(ist,k)*V(ist,k);
                                    RN(ist,k) = QN(ist,k)/TN(ist,k);
                                end
                            end
                            %                         case SchedStrategy.ID_PS
                            %                             for c=1:C
                            %                                 inchain = sn.inchain{c};
                            %                                 for k=inchain
                            %                                     TN(ist,k) = lambda(c)*V(ist,k);
                            %                                     UN(ist,k) = S(ist,k)*TN(ist,k);
                            %                                 end
                            %                                 %Nc = sum(sn.njobs(inchain)); % closed population
                            %                                 Uden = min([1-Distrib.Tol,sum(UN(ist,:))]);
                            %                                 for k=inchain
                            %                                     %QN(ist,k) = (UN(ist,k)-UN(ist,k)^(Nc+1))/(1-Uden); % geometric bound type approximation
                            %                                     QN(ist,k) = UN(ist,k)/(1-Uden);
                            %                                     RN(ist,k) = QN(ist,k)/TN(ist,k);
                            %                                 end
                            %                             end
                        case {SchedStrategy.ID_FCFS}
                            mu_ist = sn.rates(ist,1:K);
                            mu_ist(isnan(mu_ist))=0;                            
                            rho_ist_class = a1(ist,1:K)./(Distrib.Zero+sn.rates(ist,1:K));
                            rho_ist_class(isnan(rho_ist_class))=0;
                            lambda_ist = sum(a1(ist,:));
                            mi = sn.nservers(ist);
                            rho_ist = sum(rho_ist_class) / mi;
                            if rho_ist < 1-Distrib.Tol
                                for k=1:K
                                    if rho_ist > 0.7
                                        alpha_mi = (rho_ist^mi+rho_ist) / 2;
                                    else
                                        alpha_mi = rho_ist^((mi+1)/2);
                                    end
                                    mubar(ist) = lambda_ist ./ rho_ist;
                                    c2(ist) = -1;
                                    for r=1:K
                                        if mu_ist(r)>0
                                            c2(ist) = c2(ist) + a1(ist,r)/lambda_ist * (mubar(ist)/mi/mu_ist(r))^2 * (scv(ist,r)+1 );
                                        end
                                    end               
                                    Wiq(ist) = (alpha_mi / mubar(ist)) * 1/ (1-rho_ist) * (sum(a2(ist,:))+c2(ist))/2;
                                    QN(ist,k) = a1(ist,k) / mu_ist(k) + a1(ist,k)*Wiq(ist);
                                end
                                d2(ist) = 1 + rho_ist^2*(c2(ist)-1)/sqrt(mi) + (1 - rho_ist^2) *(sum(a2(ist,:))-1);
                            else
                                for k=1:K
                                    QN(ist,k) = sn.njobs(k);
                                end
                                d2(ist) = 1;
                            end
                            for k=1:K
                                TN(ist,k) = a1(ist,k);
                                UN(ist,k) = TN(ist,k) * S(ist,k) /sn.nservers(ist);
                                RN(ist,k) = QN(ist,k) ./ TN(ist,k);
                            end
                    end
            end
        else % not a station
            switch sn.nodetype(ind)
                case NodeType.Fork
                    line_error(mfilename,'Fork nodes not supported yet by QNA solver.');
            end
        end
    end    


    % splitting - update flow scvs
    for i=1:M
        for j=1:M
            if sn.nodetype(sn.stationToNode(j)) ~= NodeType.Source
                for r=1:K
                    for s=1:K
                        if rt((i-1)*K+r, (j-1)*K+s)>0
                            f2((i-1)*K+r, (j-1)*K+s) = 1 + rt((i-1)*K+r, (j-1)*K+s) * (d2(i)-1); % C^2ij,r
                        end
                    end
                end
            end
        end
    end   
end
CN = sum(RN,1);
QN = abs(QN);
QN(isnan(QN))=0;
UN(isnan(UN))=0;
RN(isnan(RN))=0;
CN(isnan(CN))=0;
XN(isnan(XN))=0;
end

function [d2]=qna_superpos(lambda,a2)
a2 = a2(isfinite(lambda));
lambda = lambda(isfinite(lambda));
d2 = a2(:)'*lambda(:) / sum(lambda);
end