function lqn = getStruct(self)
% LQN = GETSTRUCT(SELF)
%
%
% Copyright 2012-2022, Imperial College London

lqn = struct();
lqn.nidx = 0;  % total number of hosts, tasks, entries, and activities, except the reference tasks
lqn.nhosts = length(self.hosts);
lqn.ntasks = length(self.tasks);
lqn.nreftasks = length(self.reftasks);
lqn.nacts = length(self.activities);
lqn.nentries = length(self.entries);
lqn.ntasksof = [];  % number of tasks on the ith host
lqn.nentriesof = [];
lqn.nactsof = [];
lqn.tshift = lqn.nhosts;
lqn.eshift = lqn.nhosts + lqn.ntasks;
lqn.ashift = lqn.nhosts + lqn.ntasks + lqn.nentries;

for p=1:lqn.nhosts
    lqn.ntasksof(p) = length(self.hosts{p}.tasks);
end

%% analyze static properties
lqn.nidx = lqn.nhosts + lqn.ntasks + lqn.nentries + lqn.nacts;
idx = 1;
lqn.hostidx = [];
lqn.taskidx = [];
lqn.entryidx = [];
lqn.actidx = [];
lqn.tasksof = cell(lqn.nhosts,1);
lqn.entriesof = cell(lqn.nhosts+lqn.ntasks,1);
lqn.actsof = cell(lqn.nhosts+lqn.ntasks,1);
lqn.callsof = cell(lqn.nhosts+lqn.ntasks,1);
lqn.hostdem = {};
lqn.think = {};
lqn.sched = {};
lqn.schedid = [];
lqn.names = {};
lqn.hashnames = {};
%lqn.shortnames = {};
lqn.mult = zeros(lqn.nhosts+lqn.ntasks,1);
lqn.repl = zeros(lqn.nhosts+lqn.ntasks,1);
lqn.type = zeros(lqn.nidx,1);
lqn.graph = sparse([]);
lqn.replies = [];
lqn.replygraph = sparse([]);

lqn.nitems = cell(lqn.nhosts+lqn.ntasks,1);
lqn.itemlevelcap  = {};
lqn.replacementpolicy  = {};
lqn.nitemsof = {};
lqn.itemsdistribution = {};
lqn.iscache = zeros(lqn.nhosts+lqn.ntasks,1);
tshift = lqn.nhosts;
eshift = lqn.nhosts + lqn.ntasks;
ashift = lqn.nhosts + lqn.ntasks + lqn.nentries;

lqn.parent = [];
for p=1:lqn.nhosts  % for every processor, scheduling, multiplicity, replication, names, type
    lqn.hostidx(end+1) = idx;
    lqn.sched{idx,1} = SchedStrategy.fromText(self.hosts{p}.scheduling);
    lqn.schedid(idx,1) = SchedStrategy.toId(lqn.sched{idx,1});
    lqn.mult(idx,1) = self.hosts{p}.multiplicity;
    lqn.repl(idx,1) = self.hosts{p}.replication;
    lqn.names{idx,1} = self.hosts{p}.name;
    lqn.hashnames{idx,1} = ['P:',lqn.names{idx,1}];
    %lqn.shortnames{idx,1} = ['P',num2str(p)];
    lqn.type(idx,1) = LayeredNetworkElement.HOST; % processor
    idx = idx + 1;
end

for t=1:lqn.ntasks
    lqn.taskidx(end+1) = idx;
    lqn.sched{idx,1} = SchedStrategy.fromText(self.tasks{t}.scheduling);
    lqn.schedid(idx,1) = SchedStrategy.toId(lqn.sched{idx,1});
    lqn.hostdem{idx,1} = Immediate.getInstance();
    lqn.think{idx,1} = self.tasks{t}.thinkTime;
    lqn.mult(idx,1) = self.tasks{t}.multiplicity;
    lqn.repl(idx,1) = self.tasks{t}.replication;
    lqn.names{idx,1} = self.tasks{t}.name;
    switch lqn.schedid(idx,1)
        case SchedStrategy.ID_REF
            lqn.hashnames{idx,1} = ['R:',lqn.names{idx,1}];
            %lqn.shortnames{idx,1} = ['R',num2str(idx-tshift)];
        otherwise
            lqn.hashnames{idx,1} = ['T:',lqn.names{idx,1}];
            %lqn.shortnames{idx,1} = ['T',num2str(idx-tshift)];
    end
    switch class(self.tasks{t})
        case 'CacheTask'
            lqn.nitems{idx,1} = self.tasks{t}.items;
            lqn.itemlevelcap{idx,1} = self.tasks{t}.itemLevelCap;
            lqn.replacementpolicy{idx,1} = self.tasks{t}.replacementPolicy;
            lqn.hashnames{idx,1} = ['C:',lqn.names{idx,1}];
            %lqn.shortnames{idx,1} = ['C',num2str(idx-tshift)];
    end
    pidx = find(cellfun(@(x) strcmp(x.name, self.tasks{t}.parent.name), self.hosts));
    lqn.parent(idx) = pidx;
    lqn.graph(idx, pidx) = 1;
    lqn.nentriesof(idx) = length(self.tasks{t}.entries);
    lqn.nactsof(idx) = length(self.tasks{t}.activities);
    lqn.type(idx) = LayeredNetworkElement.TASK; % task
    idx = idx + 1;
end

for p=1:lqn.nhosts  % for every processor
    pidx = p;
    lqn.tasksof{pidx} = find(lqn.parent == pidx);
end

for e=1:lqn.nentries
    lqn.entryidx(end+1) = idx;
    lqn.names{idx,1} = self.entries{e}.name;
    switch class(self.entries{e})
        case 'Entry'
            lqn.hashnames{idx,1} = ['E:',lqn.names{idx,1}];
            %lqn.shortnames{idx,1} = ['E',num2str(idx-eshift)];
        case 'ItemEntry'
            lqn.hashnames{idx,1} = ['I:',lqn.names{idx,1}];
            %lqn.shortnames{idx,1} = ['I',num2str(idx-eshift)];
            lqn.nitemsof{idx,1} = self.entries{e}.cardinality;
            lqn.itemsdistribution{idx,1} = self.entries{e}.popularity;
    end
    lqn.hostdem{idx,1} = Immediate.getInstance();
    tidx = lqn.nhosts + find(cellfun(@(x) strcmp(x.name, self.entries{e}.parent.name), self.tasks));
    lqn.parent(idx) = tidx;
    lqn.graph(tidx,idx) = 1;
    lqn.entriesof{tidx}(end+1) = idx;
    lqn.type(idx) = LayeredNetworkElement.ENTRY; % entries
    idx = idx + 1;
end

for a=1:lqn.nacts
    lqn.actidx(end+1) = idx;
    lqn.names{idx,1} = self.activities{a}.name;
    lqn.hashnames{idx,1} = ['A:',lqn.names{idx,1}];
    %lqn.shortnames{idx,1} = ['A',num2str(idx - ashift)];
    lqn.hostdem{idx,1} = self.activities{a}.hostDemand;
    tidx = lqn.nhosts + find(cellfun(@(x) strcmp(x.name, self.activities{a}.parent.name), self.tasks));
    lqn.parent(idx) = tidx;
    lqn.actsof{tidx}(end+1) = idx;
    lqn.type(idx) = LayeredNetworkElement.ACTIVITY; % activities
    idx = idx + 1;
end
nidx = idx - 1; % number of indices
lqn.graph(nidx,nidx) = 0;

tasks = self.tasks;
%% now analyze calls
cidx = 0;
lqn.callidx = sparse(lqn.nidx,lqn.nidx);
lqn.calltype = sparse([],lqn.nidx,1);
lqn.iscaller = sparse(lqn.nidx,lqn.nidx);
lqn.issynccaller = sparse(lqn.nidx,lqn.nidx);
lqn.isasynccaller = sparse(lqn.nidx,lqn.nidx);
lqn.callpair = [];
lqn.callproc = {};
lqn.callnames = {};
lqn.callhashnames = {};
%lqn.callshortnames = {};
lqn.taskgraph = sparse([],lqn.ntasks, lqn.ntasks);
lqn.actpre = sparse(lqn.nidx,1);
lqn.actpost = sparse(lqn.nidx,1);

for t = 1:lqn.ntasks
    tidx = lqn.taskidx(t);
    lqn.actsof{tidx} = zeros(1,lqn.nactsof(tidx));
    for a=1:lqn.nactsof(tidx)
        aidx = findstring(lqn.hashnames, ['A:',tasks{t}.activities(a).name]);
        lqn.callsof{aidx} = [];
        lqn.actsof{tidx}(a) = aidx;
        boundToEntry = tasks{t}.activities(a).boundToEntry;
        %for b=1:length(boundToEntry)
        eidx = findstring(lqn.hashnames, ['E:',boundToEntry]);
        if eidx<0
            eidx = findstring(lqn.hashnames, ['I:',boundToEntry]);
        end
        if eidx>0
            lqn.graph(eidx, aidx) = 1;
        end
        %end

        for s=1:length(tasks{t}.activities(a).syncCallDests)
            target_eidx = findstring(lqn.hashnames, ['E:',tasks{t}.activities(a).syncCallDests{s}]);
            if target_eidx < 0
                target_eidx = findstring(lqn.hashnames, ['I:',tasks{t}.activities(a).syncCallDests{s}]);
            end
            target_tidx = lqn.parent(target_eidx);
            cidx = cidx + 1;
            lqn.callidx(aidx, target_eidx) = cidx;
            lqn.calltype(cidx,1) = CallType.ID_SYNC;
            lqn.callpair(cidx,1:2) = [aidx,target_eidx];
            lqn.callnames{cidx,1} = [lqn.names{aidx},'=>',lqn.names{target_eidx}];
            lqn.callhashnames{cidx,1} = [lqn.hashnames{aidx},'=>',lqn.hashnames{target_eidx}];
            %lqn.callshortnames{cidx,1} = [lqn.shortnames{aidx},'=>',lqn.shortnames{target_eidx}];
            lqn.callproc{cidx,1} = Geometric(1/tasks{t}.activities(a).syncCallMeans(s)); % synch
            lqn.callsof{aidx}(end+1) = cidx;
            lqn.iscaller(tidx, target_tidx) = true;
            lqn.iscaller(tidx, target_eidx) = true;
            lqn.iscaller(aidx, target_eidx) = true;
            lqn.issynccaller(tidx, target_tidx) = true;
            lqn.issynccaller(tidx, target_eidx) = true;
            lqn.issynccaller(aidx, target_eidx) = true;
            lqn.taskgraph(tidx, target_tidx) = 1;
            lqn.graph(aidx, target_eidx) = 1;
        end

        for s=1:length(tasks{t}.activities(a).asyncCallDests)
            target_eidx = findstring(lqn.hashnames,['E:',tasks{t}.activities(a).asyncCallDests{s}]);
            target_tidx = lqn.parent(target_eidx);
            cidx = cidx + 1;
            lqn.callidx(aidx, target_eidx) = cidx;
            lqn.callpair(cidx,1:2) = [aidx,target_eidx];
            lqn.calltype(cidx,1) = CallType.ID_ASYNC; % async
            lqn.callnames{cidx,1} = [lqn.names{aidx},'->',lqn.names{target_eidx}];
            lqn.callhashnames{cidx,1} = [lqn.hashnames{aidx},'->',lqn.hashnames{target_eidx}];
            %lqn.callshortnames{cidx,1} = [lqn.shortnames{aidx},'->',lqn.shortnames{target_eidx}];
            lqn.callproc{cidx,1} = Geometric(1/tasks{t}.activities(a).asyncCallMeans(s)); % asynch
            lqn.callsof{aidx}(end+1) = cidx;
            lqn.iscaller(tidx, target_tidx) = true;
            lqn.iscaller(tidx, target_eidx) = true;
            lqn.isasynccaller(tidx, target_tidx) = true;
            lqn.isasynccaller(tidx, target_eidx) = true;
            lqn.isasynccaller(aidx, target_eidx) = true;
            lqn.taskgraph(tidx, target_tidx) = 1;
            lqn.graph(aidx, target_eidx) = 1;
        end
    end

    for ap=1:length(tasks{t}.precedences)
        pretype = tasks{t}.precedences(ap).preType;
        posttype = tasks{t}.precedences(ap).postType;
        preacts = tasks{t}.precedences(ap).preActs;
        postacts = tasks{t}.precedences(ap).postActs;
        for prea = 1:length(preacts)
            preaidx = findstring(lqn.hashnames, ['A:',tasks{t}.precedences(ap).preActs{prea}]);
            switch pretype
                case ActivityPrecedence.PRE_AND
                    quorum = tasks{t}.precedences(ap).preParams;
                    if isempty(quorum)
                        preParam = 1.0;
                    else
                        preParam = quorum / length(preacts);
                    end
                otherwise
                    preParam = 1.0;
            end
            switch posttype
                case ActivityPrecedence.POST_OR
                    for posta = 1:length(postacts)
                        postaidx = findstring(lqn.hashnames, ['A:',tasks{t}.precedences(ap).postActs{posta}]);
                        probs = tasks{t}.precedences(ap).postParams;
                        postParam = probs(posta);
                        lqn.graph(preaidx, postaidx) = preParam * postParam;
                        lqn.actpre(preaidx) = sparse(ActivityPrecedence.getPrecedenceId(tasks{t}.precedences(ap).preType));
                        lqn.actpost(postaidx) = sparse(ActivityPrecedence.getPrecedenceId(tasks{t}.precedences(ap).postType));
                    end
                case ActivityPrecedence.POST_LOOP
                    counts = tasks{t}.precedences(ap).postParams;
                    % add the end activity 
                    enda = length(postacts);
                    endaidx = findstring(lqn.hashnames, ['A:',tasks{t}.precedences(ap).postActs{enda}]);
                    % add the activities inside the loop in parallel with equal probability and connected them to end activity
                    for posta = 1:(length(postacts)-1) % last one is 'end' of loop activity
                        postaidx = findstring(lqn.hashnames, ['A:',tasks{t}.precedences(ap).postActs{posta}]);
                        postParam = 1.0 / (length(postacts)-1);
                        lqn.graph(preaidx, postaidx) = preParam * postParam;
                        lqn.graph(postaidx, postaidx) = 1.0 - 1.0 / counts;
                        lqn.graph(postaidx, endaidx) = 1 / counts;
                        lqn.actpost(postaidx) = sparse(ActivityPrecedence.getPrecedenceId(tasks{t}.precedences(ap).postType));
                    end
                    lqn.actpost(endaidx) = sparse(ActivityPrecedence.getPrecedenceId(tasks{t}.precedences(ap).postType));
                otherwise
                    for posta = 1:length(postacts)
                        postaidx = findstring(lqn.hashnames, ['A:',tasks{t}.precedences(ap).postActs{posta}]);
                        postParam = 1.0;
                        lqn.graph(preaidx, postaidx) = preParam * postParam;
                        lqn.actpre(preaidx) = sparse(ActivityPrecedence.getPrecedenceId(tasks{t}.precedences(ap).preType));
                        lqn.actpost(postaidx) = sparse(ActivityPrecedence.getPrecedenceId(tasks{t}.precedences(ap).postType));
                    end
            end
        end
    end
end

lqn.replies = false(1,lqn.nidx);
lqn.replygraph = 0*lqn.graph;
for t = 1:lqn.ntasks
    tidx = lqn.taskidx(t);
    for aidx = lqn.actsof{tidx}
        postaidxs = find(lqn.graph(aidx, :));
        isreply = true;
        % if no successor is an action of tidx
        for postaidx = postaidxs
            if any(lqn.actsof{tidx} == postaidx)
                isreply = false;
            end
        end
        if isreply
            % this is a leaf node, search backward for the parent entry,
            % which is assumed to be unique
            lqn.replies(aidx) = true;
            parentidx = aidx;
            while lqn.type(parentidx) ~= LayeredNetworkElement.ENTRY
                ancestors = find(lqn.graph(:,parentidx));
                parentidx = at(ancestors,1); % only choose first ancestor
            end
            if lqn.type(parentidx) == LayeredNetworkElement.ENTRY
                lqn.replygraph(aidx, parentidx) = 1;
            end
        end
    end
end
lqn.ncalls = size(lqn.calltype,1);

% correct multiplicity for infinite server stations
for tidx = find(lqn.schedid== SchedStrategy.ID_INF)
    if lqn.type(tidx) == LayeredNetworkElement.TASK
        callers = find(lqn.taskgraph(:, tidx));
        callers_inf = strcmp(lqn.mult(callers), SchedStrategy.INF);
        if any(callers_inf)
            % if a caller is also inf, then we would need to recursively
            % determine the maximum multiplicity, we instead use a
            % heuristic value
            lqn.mult(tidx) = sum(lqn.mult(~callers_inf)) + sum(callers_inf)*max(lqn.mult);
        else
            lqn.mult(tidx) = sum(lqn.mult(callers));
        end
    end
end

lqn.isref = lqn.schedid==SchedStrategy.ID_REF;
lqn.iscache = ~cellfun(@isempty,lqn.nitems);
end