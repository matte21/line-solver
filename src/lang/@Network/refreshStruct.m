function refreshStruct(self)
% REFRESHSTRUCT()
%
% Copyright (c) 2012-2021, Imperial College London
% All rights reserved.

sanitize(self);
nodetypes = getNodeTypes(self);
classnames = getClassNames(self);
nodenames = getNodeNames(self);
njobs = getNumberOfJobs(self);
numservers = getStationServers(self);
refstat = getReferenceStations(self);

%% init minimal structure
qn = NetworkStruct(); % create in self to ensure propagation
qn.nnodes = numel(nodenames);
qn.nclasses = length(classnames);

%% get routing strategies
routing = zeros(qn.nnodes, qn.nclasses);
for ind=1:qn.nnodes
    for r=1:qn.nclasses
        switch self.nodes{ind}.output.outputStrategy{r}{2}
            case RoutingStrategy.RAND
                routing(ind,r) = RoutingStrategy.ID_RAND;
            case RoutingStrategy.PROB
                routing(ind,r) = RoutingStrategy.ID_PROB;
            case RoutingStrategy.RRB
                routing(ind,r) = RoutingStrategy.ID_RRB;
            case RoutingStrategy.JSQ
                routing(ind,r) = RoutingStrategy.ID_JSQ;
            case RoutingStrategy.DISABLED
                routing(ind,r) = RoutingStrategy.ID_DISABLED;
        end
    end
end

qn.nclosedjobs = sum(njobs(isfinite(njobs)));
qn.nservers = numservers;
qn.isstation = NodeType.isStation(nodetypes);
qn.nstations = sum(qn.isstation);
qn.nodetype = -1*ones(qn.nstations,1);
qn.scv = ones(qn.nstations,qn.nclasses);
%qn.forks = zeros(M,K);
qn.njobs = njobs(:)';
qn.refstat = refstat;
qn.space = cell(qn.nstations,1);
qn.routing = routing;
qn.chains = [];
qn.lst = {};
qn.nodetype = nodetypes;
qn.nstations = sum(qn.isstation);
qn.isstateful = NodeType.isStateful(nodetypes);
qn.isstatedep = false(qn.nnodes,3); % col 1: buffer, col 2: srv, col 3: routing
for ind=1:qn.nnodes
    switch qn.nodetype(ind)
        case NodeType.Cache
            qn.isstatedep(ind,2) = true; % state dependent service
            %                            qn.isstatedep(ind,3) = true; % state dependent routing
            %         case NodeType.Place
            %             self.nodes{ind}.init();
            %         case NodeType.Transition
            %             self.nodes{ind}.init(); % this erases enablingConditions
    end
    for r=1:qn.nclasses
        switch qn.routing(ind,r)
            case {RoutingStrategy.ID_RRB, RoutingStrategy.ID_JSQ}
                qn.isstatedep(ind,3) = true; % state dependent routing
        end
    end
end
qn.nstateful = sum(qn.isstateful);
qn.state = cell(qn.nstations,1);
for i=1:qn.nstateful
    qn.state{i} = [];
end
qn.nodenames = nodenames;
qn.classnames = classnames;

qn.modenames = cell(qn.nnodes,1);
qn.nmodes = zeros(qn.nnodes,1);
qn.nmodeservers = cell(qn.nnodes,1);
qn.enabling = cell(qn.nnodes,1);
qn.firing = cell(qn.nnodes,1);
qn.fireprio = cell(qn.nnodes,1);
qn.fireweight = cell(qn.nnodes,1);
qn.firingid = cell(qn.nnodes,1);
qn.firingproc = cell(qn.nnodes,1);
qn.firingprocid = cell(qn.nnodes,1);
qn.firingphases = cell(qn.nnodes,1);
qn.inhibiting = cell(qn.nnodes,1);

qn.nodeToStateful =[];
qn.nodeToStation =[];
qn.stationToNode =[];
qn.stationToStateful =[];
qn.statefulToNode =[];
for ind=1:qn.nnodes
    qn.nodeToStateful(ind) = nd2sf(qn,ind);
    qn.nodeToStation(ind) = nd2st(qn,ind);
end
for ist=1:qn.nstations
    qn.stationToNode(ist) = st2nd(qn,ist);
    qn.stationToStateful(ist) = st2sf(qn,ist);
end
for isf=1:qn.nstateful
    qn.statefulToNode(isf) = sf2nd(qn,isf);
end

self.qn = qn;
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
%qn.forks = self.getForks(qn.rt);
end

function stat_idx = nd2st(qn, node_idx)
% STAT_IDX = ND2ST(NODE_IDX)

if qn.isstation(node_idx)
    stat_idx = at(cumsum(qn.isstation),node_idx);
else
    stat_idx = NaN;
end
end

function node_idx = st2nd(qn,stat_idx)
% NODE_IDX = ST2ND(SELF,STAT_IDX)

v = cumsum(qn.isstation) == stat_idx;
if any(v)
    node_idx =  find(v, 1);
else
    node_idx = NaN;
end
end

function sful_idx = st2sf(qn,stat_idx)
% SFUL_IDX = ST2SF(SELF,STAT_IDX)

sful_idx = nd2sf(qn,st2nd(qn,stat_idx));
end

function sful_idx = nd2sf(qn, node_idx)
% SFUL_IDX = ND2SF(NODE_IDX)

if qn.isstateful(node_idx)
    sful_idx = at(cumsum(qn.isstateful),node_idx);
else
    sful_idx = NaN;
end
end

function node_idx = sf2nd(qn,stat_idx)
% NODE_IDX = SF2ND(SELF,STAT_IDX)

v = cumsum(qn.isstateful) == stat_idx;
if any(v)
    node_idx =  find(v, 1);
else
    node_idx = NaN;
end
end
