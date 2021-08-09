function refreshStruct(self, hardRefresh)
% REFRESHSTRUCT()
%
% Copyright (c) 2012-2021, Imperial College London
% All rights reserved.

sanitize(self);
if nargin<2
    hardRefresh = true;
end

%% store invariant information
if self.hasStruct && ~hardRefresh
    rtorig = self.sn.rtorig; % this must be destroyed with resetNetwork
end

if self.hasStruct && ~hardRefresh
    nodetypes = sn.nodetypes;
    classnames = sn.classnames;
    nodenames = sn.nodenames;
    refstat = sn.refstat;
else
    nodetypes = getNodeTypes(self);
    classnames = getClassNames(self);
    nodenames = getNodeNames(self);
    refstat = getReferenceStations(self);
end
njobs = getNumberOfJobs(self);
numservers = getStationServers(self);
lldscaling = getLimitedLoadDependence(self);

%% init minimal structure
sn = NetworkStruct(); % create in self to ensure propagation
if isempty(self.sn)
    sn.rtorig = [];
else
    sn.rtorig = self.sn.rtorig;
end
sn.nnodes = numel(nodenames);
sn.nclasses = length(classnames);

%% get routing strategies
routing = zeros(sn.nnodes, sn.nclasses);
for ind=1:sn.nnodes
    for r=1:sn.nclasses
        switch self.nodes{ind}.output.outputStrategy{r}{2}
            case RoutingStrategy.RAND
                routing(ind,r) = RoutingStrategy.ID_RAND;
            case RoutingStrategy.PROB
                routing(ind,r) = RoutingStrategy.ID_PROB;
            case RoutingStrategy.RROBIN
                routing(ind,r) = RoutingStrategy.ID_RROBIN;
            case RoutingStrategy.JSQ
                routing(ind,r) = RoutingStrategy.ID_JSQ;
            case RoutingStrategy.DISABLED
                routing(ind,r) = RoutingStrategy.ID_DISABLED;
        end
    end
end

sn.nclosedjobs = sum(njobs(isfinite(njobs)));
sn.nservers = numservers;
sn.isstation = NodeType.isStation(nodetypes);
sn.nstations = sum(sn.isstation);
sn.nodetype = -1*ones(sn.nstations,1);
sn.scv = ones(sn.nstations,sn.nclasses);
%sn.forks = zeros(M,K);
sn.njobs = njobs(:)';
sn.refstat = refstat;
sn.space = cell(sn.nstations,1);
sn.routing = routing;
sn.chains = [];
sn.lst = {};
sn.lldscaling = lldscaling;
sn.nodetype = nodetypes;
sn.nstations = sum(sn.isstation);
sn.isstateful = NodeType.isStateful(nodetypes);
sn.isstatedep = false(sn.nnodes,3); % col 1: buffer, col 2: srv, col 3: routing
for ind=1:sn.nnodes
    switch sn.nodetype(ind)
        case NodeType.Cache
            sn.isstatedep(ind,2) = true; % state dependent service
            %                            sn.isstatedep(ind,3) = true; % state dependent routing
            %         case NodeType.Place
            %             self.nodes{ind}.init();
            %         case NodeType.Transition
            %             self.nodes{ind}.init(); % this erases enablingConditions
    end
    for r=1:sn.nclasses
        switch sn.routing(ind,r)
            case {RoutingStrategy.ID_RROBIN, RoutingStrategy.ID_JSQ}
                sn.isstatedep(ind,3) = true; % state dependent routing
        end
    end
end
sn.nstateful = sum(sn.isstateful);
sn.state = cell(sn.nstations,1);
for i=1:sn.nstateful
    sn.state{i} = [];
end
sn.nodenames = nodenames;
sn.classnames = classnames;

sn.modenames = cell(sn.nnodes,1);
sn.nmodes = zeros(sn.nnodes,1);
sn.nmodeservers = cell(sn.nnodes,1);
sn.enabling = cell(sn.nnodes,1);
sn.firing = cell(sn.nnodes,1);
sn.fireprio = cell(sn.nnodes,1);
sn.fireweight = cell(sn.nnodes,1);
sn.firingid = cell(sn.nnodes,1);
sn.firingproc = cell(sn.nnodes,1);
sn.firingprocid = cell(sn.nnodes,1);
sn.firingphases = cell(sn.nnodes,1);
sn.inhibiting = cell(sn.nnodes,1);

sn.nodeToStateful =[];
sn.nodeToStation =[];
sn.stationToNode =[];
sn.stationToStateful =[];
sn.statefulToNode =[];
for ind=1:sn.nnodes
    sn.nodeToStateful(ind) = nd2sf(sn,ind);
    sn.nodeToStation(ind) = nd2st(sn,ind);
end
for ist=1:sn.nstations
    sn.stationToNode(ist) = st2nd(sn,ist);
    sn.stationToStateful(ist) = st2sf(sn,ist);
end
for isf=1:sn.nstateful
    sn.statefulToNode(isf) = sf2nd(sn,isf);
end

self.sn = sn;
refreshPriorities(self);
refreshService(self);
if any(nodetypes == NodeType.Cache)
    self.refreshChains(false); % wantVisits
else
    self.refreshChains(true); % wantVisits
end
refreshLocalVars(self); % depends on chains (rtnodes)
refreshSync(self); % this assumes that refreshChain is called before
refreshPetriNetNodes(self);
self.hasStruct = true;
%sn.forks = self.getForks(sn.rt);
end

function stat_idx = nd2st(sn, node_idx)
% STAT_IDX = ND2ST(NODE_IDX)

if sn.isstation(node_idx)
    stat_idx = at(cumsum(sn.isstation),node_idx);
else
    stat_idx = NaN;
end
end

function node_idx = st2nd(sn,stat_idx)
% NODE_IDX = ST2ND(SELF,STAT_IDX)

v = cumsum(sn.isstation) == stat_idx;
if any(v)
    node_idx =  find(v, 1);
else
    node_idx = NaN;
end
end

function sful_idx = st2sf(sn,stat_idx)
% SFUL_IDX = ST2SF(SELF,STAT_IDX)

sful_idx = nd2sf(sn,st2nd(sn,stat_idx));
end

function sful_idx = nd2sf(sn, node_idx)
% SFUL_IDX = ND2SF(NODE_IDX)

if sn.isstateful(node_idx)
    sful_idx = at(cumsum(sn.isstateful),node_idx);
else
    sful_idx = NaN;
end
end

function node_idx = sf2nd(sn,stat_idx)
% NODE_IDX = SF2ND(SELF,STAT_IDX)

v = cumsum(sn.isstateful) == stat_idx;
if any(v)
    node_idx =  find(v, 1);
else
    node_idx = NaN;
end
end
