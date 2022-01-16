function [chains, visits, rt] = refreshChains(self, propagate)
% [CHAINS, VISITS, RT] = REFRESHCHAINS(PROPAGATE)
%
% PROPAGATE : true if the change needs to trigger recomputation of visits and station capacities (default: true)

% Copyright (c) 2012-2022, Imperial College London
% All rights reserved.

if nargin<2
    propagate = true;
end
if nargin<3
    propagate = true;
end

%% obtain routing matrix
rates = self.sn.rates;
[rt,~,rtnodes] = self.refreshRoutingMatrix(rates);
self.sn.rt = rt;
self.sn.rtnodes = rtnodes;

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
    ind = self.sn.statefulToNode(isf);
    isCS = self.sn.nodetype(ind) == NodeType.Cache | self.sn.nodetype(ind) == NodeType.ClassSwitch;
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
self.sn.csmask = csmask;

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

%if ~isempty(self.sn)
self.sn.chains = logical(chains);
self.sn.nchains = size(chains,1);
for c=1:C
    if range(self.sn.refstat(self.sn.chains(c,:)))
        line_error(mfilename,sprintf('Classes within chain %d (classes: %s) have different reference stations.',c,mat2str(find(self.sn.chains(c,:)))));
    end
end

if propagate
    [visits, nodevisits] = self.refreshVisits(chains, rt, rtnodes);
    self.sn.visits = visits;
    self.sn.nodevisits = nodevisits;
end
%end

self.sn.isslc = false(self.sn.nchains,1);
for c=1:self.sn.nchains
    if nnz(self.sn.visits{c}) == 1
        self.sn.isslc(c) = true;
    end
end

%% call dependent capacity refresh
if propagate
    refreshCapacity(self); % capacity depends on chains and rates
end

end