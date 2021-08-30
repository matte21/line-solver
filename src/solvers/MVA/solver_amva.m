function [Q,U,R,T,C,X,lG] = solver_amva(sn,options)
% [Q,U,R,T,C,X,lG] = SOLVER_AMVA(SN, OPTIONS)
%
% Copyright (c) 2012-2021, Imperial College London
% All rights reserved.
if nargin < 2
    options = SolverMVA.defaultOptions;
end

[Lchain,STchain,Vchain,alpha,Nchain,SCVchain,refstatchain] = snGetDemandsChain(sn);

M = sn.nstations;
K = sn.nchains;
Nt = sum(Nchain(isfinite(Nchain)));
delta  = (Nt - 1) / Nt;
deltaclass = (Nchain - 1) ./ Nchain;
deltaclass(isinf(Nchain)) = 1;
tol = options.iter_tol;
nservers = sn.nservers;

Uchain = zeros(M,K);
Tchain = zeros(M,K);
Cchain = zeros(1,K);

%% initialize Q,X, U
iter = 0;
Qchain = options.init_sol;
if isempty(Qchain)
    % balanced initialization
    Qchain = ones(M,K);
    Qchain = Qchain ./ repmat(sum(Qchain,1),size(Qchain,1),1) .* repmat(Nchain,size(Qchain,1),1);
    Qchain(isinf(Qchain))=0; % open classes
    Qchain(refstatchain(isinf(Nchain)))=0;
end

nnzclasses = find(Nchain>0);
Xchain = 1./sum(STchain,1);
for r=find(isinf(Nchain)) % open classes
    Xchain(r) = 1 ./ STchain(refstatchain(r),r);
end

for k=1:M
    for r=nnzclasses
        if isinf(nservers(k)) % infinite server
            Uchain(k,r) = Vchain(k,r)*STchain(k,r)*Xchain(r);
        else
            Uchain(k,r) = Vchain(k,r)*STchain(k,r)*Xchain(r)/nservers(k);
        end
    end
end

if ~isfield(options.config,'multiserver')
    options.config.multiserver = 'default';
end

%% main loop
while (iter < 2 || max(max(abs(Qchain-Qchain_1))) > tol) && iter <= options.iter_max
    iter = iter + 1;
    
    Qchain_1 = Qchain;
    Xchain_1 = Xchain;
    Uchain_1 = Uchain;
        
    [Wchain, STeff] = solver_amva_iter(sn, Qchain_1, Xchain_1, Uchain_1, STchain, Vchain, Nchain, SCVchain, options);
    
    %% update other metrics
    for r=nnzclasses
        if sum(Wchain(:,r)) == 0
            Xchain(r) = 0;
        else
            if isinf(Nchain(r))
                Cchain(r) = Vchain(:,r)'*Wchain(:,r);
                % X(r) remains constant
            elseif Nchain(r)==0
                Xchain(r) = 0;
                Cchain(r) = 0;
            else
                Cchain(r) = Vchain(:,r)'*Wchain(:,r);
                Xchain(r) = Nchain(r) / Cchain(r);
            end
        end
        for k=1:M
            Rchain(k,r) = Vchain(k,r) * Wchain(k,r);
            Qchain(k,r) = Xchain(r) * Vchain(k,r) * Wchain(k,r);
            Tchain(k,r) = Xchain(r) * Vchain(k,r);
        end
    end
    for k=1:M
        for r=nnzclasses
            if isinf(nservers(k)) % infinite server
                Uchain(k,r) = Vchain(k,r)*STchain(k,r)*Xchain(r);
            else
                if strcmpi(options.method,'default') || strcmpi(options.method,'amva') || strcmpi(options.method,'amva.qd') || strcmpi(options.method,'qd')
                    Uchain(k,r) = Vchain(k,r)*STchain(k,r)*Xchain(r);
                else
                    Uchain(k,r) = Vchain(k,r)*STchain(k,r)*Xchain(r)/nservers(k);
                end
            end
        end
    end
    
end

% the next block is a coarse approximation for LD and CD, would need
% cdterm and qterm in it but these are hidden within the iteration calls
for k=1:M
    for r=1:K
        if strcmpi(options.method,'default') || strcmpi(options.method,'amva') || strcmpi(options.method,'amva.qd') || strcmpi(options.method,'qd')
            if Vchain(k,r) * STeff(k,r) >0
                switch sn.schedid(k)
                    case {SchedStrategy.ID_FCFS, SchedStrategy.ID_PS, SchedStrategy.ID_LCFSPR, SchedStrategy.ID_DPS}
                        if sum(Uchain(k,:))>1 % in the next expression, qdterm simplifies
                            Uchain(k,r) = min(1,sum(Uchain(k,:))) * Vchain(k,r) * STeff(k,r) * Xchain(r) / ((Vchain(k,:) .* STeff(k,:))*Xchain(:));
                        end
                end
            end
        else
            if Vchain(k,r) * STchain(k,r) >0
                switch sn.schedid(k)
                    case {SchedStrategy.ID_FCFS, SchedStrategy.ID_PS, SchedStrategy.ID_LCFSPR, SchedStrategy.ID_DPS}
                        if sum(Uchain(k,:))>1
                            Uchain(k,r) = min(1,sum(Uchain(k,:))) * Vchain(k,r) * STchain(k,r) * Xchain(r) / ((Vchain(k,:) .* STchain(k,:)) * Xchain(:));
                        end
                end
            end
        end
    end
end

Rchain = Qchain./Tchain;
Xchain(~isfinite(Xchain))=0;
Uchain(~isfinite(Uchain))=0;
%Qchain(~isfinite(Qchain))=0;
Rchain(~isfinite(Rchain))=0;

Xchain(Nchain==0)=0;
Uchain(:,Nchain==0)=0;
%Qchain(:,Nchain==0)=0;
Rchain(:,Nchain==0)=0;
Tchain(:,Nchain==0)=0;

if isempty(sn.lldscaling) && isempty(sn.cdscaling)
    [Q,U,R,T,C,X] = snDeaggregateChainResults(sn, Lchain, [], STchain, Vchain, alpha, [], [], Rchain, Tchain, [], Xchain);
else
    [Q,U,R,T,C,X] = snDeaggregateChainResults(sn, Lchain, [], STchain, Vchain, alpha, [], Uchain, Rchain, Tchain, [], Xchain);
end

% estimate normalizing constant for closed classes
ccl = isfinite(Nchain);
Nclosed = Nchain(ccl);
Xclosed = Xchain(ccl);
lG = - Nclosed(Xclosed>options.tol) * log(Xclosed(Xclosed>options.tol))'; % asymptotic approximation
end