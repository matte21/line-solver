function space = spaceLocalVars(sn, ind)
% SPACE = SPACELOCALVARS(QN, IND)

% Copyright (c) 2012-2021, Imperial College London
% All rights reserved.

% Generate state space for local state variables

%ind: node index
%ist = sn.nodeToStation(ind);
%isf = sn.nodeToStateful(ind);

space = [];

switch sn.nodetype(ind)
    case NodeType.Cache
        space = State.spaceCache(sn.varsparam{ind}.nitems,sn.varsparam{ind}.cap);
end

switch sn.routing(ind)
    case RoutingStrategy.ID_RRB
        space = State.decorate(space, sn.varsparam{ind}.outlinks(:));
end
end
