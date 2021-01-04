function [lambda,D,N,Z,mu,S]= networkstruct_getproductformparams(qn)
% [LAMBDA,D,N,Z,MU,S]= NETWORKSTRUCT_GETPRODUCTFORMPARAMS()

% mu also returns max(S) elements after population |N| as this is
% required by MVALDMX

R = qn.nclasses;
N = qn.njobs;
queueIndices = find(qn.nodetype == NodeType.Queue);
delayIndices = find(qn.nodetype == NodeType.Delay);
sourceIndex = find(qn.nodetype == NodeType.Source);
Mq = length(queueIndices); % number of queues
Mz = length(delayIndices); % number of delays
lambda = zeros(1,R);
S = qn.nservers(queueIndices);
for r=1:R
    if isinf(N(r))
        lambda(r) = qn.rates(sourceIndex,r);
    end
end

D = zeros(Mq,R);
Nct = sum(N(isfinite(N)));
mu = ones(Mq, Nct+max(S(isfinite(S))));
for i=1:Mq
    for r=1:R
        c = find(qn.chains(:,r));
        D(i,r) = qn.visits{c}(queueIndices(i),r) / qn.rates(queueIndices(i),r);
    end
    mu(i,1:size(mu,2)) = min(1:size(mu,2), qn.nservers(queueIndices(i)));
end
Z = zeros(max(1,Mz),R);
for i=1:Mz
    for r=1:R
        c = find(qn.chains(:,r));
        Z(i,r) = qn.visits{c}(delayIndices(i),r) / qn.rates(delayIndices(i),r);
    end
end
end
