function [chains, visits, rt] = refreshChains(self, propagate)
% [CHAINS, VISITS, RT] = REFRESHCHAINS(PROPAGATE)
%
% PROPAGATE : true if the change needs to trigger recomputation of visits and station capacities (default: true)

% Copyright (c) 2012-2021, Imperial College London
% All rights reserved.

if nargin<2
    propagate = true;
end
if nargin<3
    propagate = true;
end

%% obtain routing matrix
rates = self.qn.rates;
[rt,~,rtnodes] = self.refreshRoutingMatrix(rates);
self.qn.rt = rt;
self.qn.rtnodes = rtnodes;
self.qn.rtorig = self.linkedRoutingTable;

%% determine class switching mask
K = getNumberOfClasses(self);
stateful = self.getIndexStatefulNodes;
csmask = false(K,K);
for r=1:K
    for s=1:K
        for isf=1:length(stateful) % source
            for jsf=1:length(stateful) % source
                if rt((isf-1)*K+r, (jsf-1)*K+s) > 0
                    % this is to ensure that we use rt, which is
                    % the stochastic complement taken over the stateful
                    % nodes, otherwise sequences of cs can produce a wrong
                    % csmask
                    csmask(r,s) = true;
                end
            end
        end
    end
end

for isf=1:length(stateful) % source
    % this is to ensure that also stateful cs like caches
    % are accounted
    ind = self.qn.statefulToNode(isf);
    isCS = self.qn.nodetype(ind) == NodeType.Cache | self.qn.nodetype(ind) == NodeType.ClassSwitch;
    for r=1:K
        csmask(r,r) = true;
        for s=1:K
            if r~=s
                if isCS
                    if self.nodes{ind}.server.csFun(r,s,[],[])>0
                        csmask(r,s) = true;
                    end
                end
            end
        end
    end
end
self.qn.csmask = csmask;

%% compute chains
[C,inChain] = weaklyconncomp(csmask+csmask');

chainCandidates = cell(1,C);
for c=1:C
    chainCandidates{c} = find(inChain==c);
end

chains = false(length(chainCandidates),0);
for t=1:length(chainCandidates)
    chains(t,chainCandidates{t}) = true;
end

try
    chains = sortrows(chains,'descend');
catch
    chains = sortrows(chains);
end

%% call dependent visits refresh

%if ~isempty(self.qn)
self.qn.chains = logical(chains);
self.qn.nchains = size(chains,1);

if propagate
    [visits, nodevisits] = self.refreshVisits(chains, rt, rtnodes);
    self.qn.visits = visits;
    self.qn.nodevisits = nodevisits;
end
%end

self.qn.isslc = false(self.qn.nchains,1);
for c=1:self.qn.nchains
    if nnz(self.qn.visits{c}) == 1
        self.qn.isslc(c) = true;
    end
end

%% call dependent capacity refresh
if propagate
    refreshCapacity(self); % capacity depends on chains and rates
end

end