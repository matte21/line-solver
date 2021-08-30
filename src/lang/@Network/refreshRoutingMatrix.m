function [rt, rtfun, rtnodes] = refreshRoutingMatrix(self, rates)
% [RT, RTFUN, CSMASK, RTNODES] = REFRESHROUTINGMATRIX(RATES)
%
% Copyright (c) 2012-2021, Imperial College London
% All rights reserved.

if nargin == 1
    if isempty(self.sn)
        line_error(mfilename,'refreshRoutingMatrix cannot retrieve station rates, pass them as an input parameters.');
    else
        rates = self.sn.rates;
    end
end

sn = self.sn;
M = self.getNumberOfNodes;
K = getNumberOfClasses(self);
arvRates = zeros(1,K);
stateful = self.getIndexStatefulNodes;

for r = self.getIndexOpenClasses
    arvRates(r) = rates(self.getIndexSourceStation,r);
end

[rt, rtnodes, linksmat] = self.getRoutingMatrix(arvRates);

for r=1:self.sn.nclasses
    if all(self.sn.routing(:,r) == -1)
        line_error(mfilename,sprintf('Routing strategy in class %d is unspecified at all nodes.',r));
    end
end

isStateDep = any(sn.isstatedep(:,3));

rnodefuncell = cell(M*K,M*K);

if isStateDep
    for ind=1:M % from
        for jnd=1:M % to
            for r=1:K
                for s=1:K
                    if sn.isstatedep(ind,3)
                        switch sn.routing(ind,r)
                            case RoutingStrategy.ID_RROBIN
                                rnodefuncell{(ind-1)*K+r, (jnd-1)*K+s} = @(state_before, state_after) sub_rr(ind, jnd, r, s, linksmat, state_before, state_after);
                            case RoutingStrategy.ID_JSQ
                                rnodefuncell{(ind-1)*K+r, (jnd-1)*K+s} = @(state_before, state_after) sub_jsq(ind, jnd, r, s, linksmat, state_before, state_after);
                            otherwise
                                rnodefuncell{(ind-1)*K+r, (jnd-1)*K+s} = @(~,~) rtnodes((ind-1)*K+r, (jnd-1)*K+s);
                        end
                    else
                        rnodefuncell{(ind-1)*K+r, (jnd-1)*K+s} = @(~,~) rtnodes((ind-1)*K+r, (jnd-1)*K+s);
                    end
                end
            end
        end
    end
end

statefulNodesClasses = [];
for ind=getIndexStatefulNodes(self)
    statefulNodesClasses(end+1:end+K)= ((ind-1)*K+1):(ind*K);
end

% we now generate the node routing matrix for the given state and then
% lump the states for non-stateful nodes so that run gives the routing
% touble for stateful nodes only
statefulNodesClasses = [];
for ind=stateful
    statefulNodesClasses(end+1:end+K)= ((ind-1)*K+1):(ind*K);
end

if isStateDep
    rtfunraw = @(state_before, state_after) dtmc_stochcomp(cell2mat(cellfun(@(f) f(state_before, state_after), rnodefuncell,'UniformOutput',false)), statefulNodesClasses);
    rtfun = rtfunraw;
    %rtfun = memoize(rtfunraw); % memoize to reduce the number of stoch comp calls
    %rtfun.CacheSize = 6000^2;
else
    rtfun = @(state_before, state_after) dtmc_stochcomp(rtnodes, statefulNodesClasses);
end

if ~isempty(self.sn)
    self.sn.rt = rt;
    self.sn.rtnodes = rtnodes;
    self.sn.rtfun = rtfun;
end

    function p = sub_rr(ind, jnd, r, s, linksmat, state_before, state_after)
        % P = SUB_RR(IND, JND, R, S, LINKSMAT, STATE_BEFORE, STATE_AFTER)
        
        isf = sn.nodeToStateful(ind);
        if isempty(state_before{isf})
            p = min(linksmat(ind,jnd),1);
        else
            if r==s
                p = double(state_after{isf}(end-r+1)==jnd);
            else
                p = 0;
            end
        end
    end

    function p = sub_jsq(ind, jnd, r, s, linksmat, state_before, state_after) %#ok<INUSD>
        % P = SUB_JSQ(IND, JND, R, S, LINKSMAT, STATE_BEFORE, STATE_AFTER) %#OK<INUSD>
        
        isf = sn.nodeToStateful(ind);
        if isempty(state_before{isf})
            p = min(linksmat(ind,jnd),1);
        else
            if r==s
                n = Inf*ones(1,sn.nnodes);
                for knd=1:sn.nnodes
                    if linksmat(ind,knd)
                        ksf = sn.nodeToStateful(knd);
                        n(knd) = State.toMarginal(sn, knd, state_before{ksf});
                    end
                end
                if n(jnd) == min(n)
                    p = 1 / sum(n == min(n));
                else
                    p = 0;
                end
            else
                p = 0;
            end
        end
    end

end
