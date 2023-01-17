function space = spaceLocalVars(sn, ind)
% SPACE = SPACELOCALVARS(QN, IND)

% Copyright (c) 2012-2023, Imperial College London
% All rights reserved.

% Generate state space for local state variables

%ind: node index
%ist = sn.nodeToStation(ind);
%isf = sn.nodeToStateful(ind);

space = [];

switch sn.nodetype(ind)
    case NodeType.Cache
        space = State.spaceCache(sn.nodeparam{ind}.nitems,sn.nodeparam{ind}.itemcap);
end

for r=1:sn.nclasses
    switch sn.routing(ind,r)
        case {RoutingStrategy.ID_RROBIN, RoutingStrategy.ID_WRROBIN}
            space = State.decorate(space, sn.nodeparam{ind}{r}.outlinks(:));
    end
end
end
