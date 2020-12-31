function [Q,U,R,T,C,X,lG] = solver_mva(ST,V,N,S,~,schedid,refstat)
% [Q,U,R,T,C,X,LG] = SOLVER_MVA(ST,V,N,S,OPTIONS,SCHEDID,REFSTAT)

% Copyright (c) 2012-2021, Imperial College London
% All rights reserved.
[M,K]=size(ST);

if nargin < 6 %schedid
    schedid = nan(M,1);
    for i=1:M
        if isinf(S(i))
            schedid(i) = SchedStrategy.ID_INF;
        else
            schedid(i) = SchedStrategy.ID_PS; % default for non-inf servers is PS
        end
    end
end

infSET = find(schedid==SchedStrategy.ID_INF);
if K==1
    pfSET = find(schedid==SchedStrategy.ID_SIRO | schedid==SchedStrategy.ID_PS | schedid==SchedStrategy.ID_FCFS);
else
    pfSET = find(schedid==SchedStrategy.ID_SIRO | schedid==SchedStrategy.ID_PS);
end

U = zeros(M,K);
T = zeros(M,K);
C = zeros(1,K);
W = zeros(M,K);
Q = zeros(M,K);

lambda = zeros(1,K);
ocl = find(isinf(N));
if any(isinf(N))
    for r=ocl % open classes
        lambda(r) = 1 ./ ST(refstat(r),r);
        Q(refstat(r),r) = Inf;
    end
end
rset = setdiff(1:K,find(N==0));

[X,Qpf,U,~,lG] = pfqn_mvams(lambda,ST(pfSET,:).*V(pfSET,:),N,ST(infSET,:).*V(infSET,:),ones(length(pfSET),1),S(pfSET));
Q(pfSET,:) = Qpf;
Q(infSET,:) = repmat(X,numel(infSET),1) .* ST(infSET,:) .* V(infSET,:);

ccl = find(isfinite(N));
for r=rset
    for k=infSET(:)'
        W(k,r) = ST(k,r);
    end
    for k=pfSET(:)'
        if isinf(S(k)) % infinite server
            W(k,r) = ST(k,r);
        else
            if V(k,r) == 0 || X(r) == 0
                W(k,r) = 0;
            else
                W(k,r) = Q(k,r) / (X(r) * V(k,r));
            end
        end
    end
end

for r=rset
    if sum(W(:,r)) == 0
        X(r) = 0;
    else
        if isinf(N(r))
            C(r) = V(:,r)'*W(:,r);
            % X(r) remains constant
        elseif N(r)==0
            X(r) = 0;
            C(r) = 0;
        else
            C(r) = V(:,r)'*W(:,r);
            X(r) = N(r) / C(r);
        end
    end
    
    for k=1:M
        Q(k,r) = X(r) * V(k,r) * W(k,r);
        T(k,r) = X(r) * V(k,r);
    end
end

for k=1:M
    for r=rset
        if isinf(S(k)) % infinite server
            U(k,r) = V(k,r)*ST(k,r)*X(r);
        else
            U(k,r) = V(k,r)*ST(k,r)*X(r)/S(k);
        end
    end
end

for k=1:M
    for r=1:K
        if V(k,r)*ST(k,r)>0
            switch schedid(k)
                case {SchedStrategy.ID_FCFS,SchedStrategy.ID_PS}
                    if sum(U(k,:))>1
                        U(k,r) = min(1,sum(U(k,:))) * V(k,r)*ST(k,r)*X(r) / ((V(k,:).*ST(k,:))*X(:));
                    end
            end
        end
    end
end

R = Q./T;
X(~isfinite(X))=0;
U(~isfinite(U))=0;
Q(~isfinite(Q))=0;
R(~isfinite(R))=0;

X(N==0)=0;
U(:,N==0)=0;
Q(:,N==0)=0;
R(:,N==0)=0;
T(:,N==0)=0;
W(:,N==0)=0;

end
