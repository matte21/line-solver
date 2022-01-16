function [lambda,D,N,Z,mu,S]= networkstruct_getproductformparams(sn)
% [LAMBDA,D,N,Z,MU,S]= NETWORKSTRUCT_GETPRODUCTFORMPARAMS()

% mu also returns max(S) elements after population |N| as this is
% required by MVALDMX

R = sn.nclasses;
N = sn.njobs;
queueIndices = find(sn.nodetype == NodeType.Queue);
delayIndices = find(sn.nodetype == NodeType.Delay);
sourceIndex = find(sn.nodetype == NodeType.Source);
Mq = length(queueIndices); % number of queues
Mz = length(delayIndices); % number of delays
lambda = zeros(1,R);
S = sn.nservers(queueIndices);
for r=1:R
    if isinf(N(r))
        lambda(r) = sn.rates(sourceIndex,r);
    end
end

D = zeros(Mq,R);
Nct = sum(N(isfinite(N)));
mu = ones(Mq, Nct+max(S(isfinite(S))));
for i=1:Mq
    for r=1:R
        c = find(sn.chains(:,r));
        D(i,r) = sn.visits{c}(queueIndices(i),r) / sn.rates(queueIndices(i),r);
    end
    mu(i,1:size(mu,2)) = min(1:size(mu,2), sn.nservers(queueIndices(i)));
end
Z = zeros(max(1,Mz),R);
for i=1:Mz
    for r=1:R
        c = find(sn.chains(:,r));
        Z(i,r) = sn.visits{c}(delayIndices(i),r) / sn.rates(delayIndices(i),r);
    end
end
end
