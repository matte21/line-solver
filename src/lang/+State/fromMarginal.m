function space = fromMarginal(sn, ind, n, options)
% SPACE = FROMMARGINAL(QN, IND, N, OPTIONS)

% Copyright (c) 2012-2023, Imperial College London
% All rights reserved.

if nargin<4 %~exist('options','var')
    options.force = false;
end
if isa(sn,'Network')
    sn=sn.getStruct();
end


% generate states such that the marginal queue-lengths are as in vector n
%  n(r): number of jobs at the station in class r
R = sn.nclasses;
S = sn.nservers;
state = [];
space = [];


if sn.isstation(ind) && any(sn.procid(sn.nodeToStation(ind),:)==ProcessType.ID_MAP | sn.procid(sn.nodeToStation(ind),:)==ProcessType.ID_MMPP2)
    if sn.nservers(ind)>1
        line_error(mfilename,'Multiserver MAP stations are not supported.')
    end
    if sn.schedid(ind) ~= SchedStrategy.ID_FCFS & sn.nodetype ~= NodeType.ID_SOURCE
        line_error(mfilename,'Non-FCFS MAP stations are not supported.')
    end
end

% ind: node index
ist = sn.nodeToStation(ind);
isf = sn.nodeToStateful(ind);

if sn.isstateful(ind) && ~sn.isstation(ind)
    for r=1:R
        init_r = State.spaceClosedSingle(1,n(r));
        state = State.decorate(state,init_r);
    end
    space = State.decorate(space,state);
    return
end

phases = zeros(1,R);
for r=1:R
    if isempty(sn.proc{ist}{r})
        phases(r) = 0;
    else
        phases(r) = length(sn.proc{ist}{r}{1});
    end
end
if (sn.schedid(ist) ~= SchedStrategy.ID_EXT) && any(n>sn.classcap(ist,:))
    return
end

% generate local-state space
switch sn.nodetype(ind)
    case {NodeType.Queue, NodeType.Delay, NodeType.Source, NodeType.Place}
        switch sn.schedid(ist)
            case SchedStrategy.ID_EXT
                for r=1:R
                    if ~isempty(sn.proc) && ~isempty(sn.proc{ist}{r}) && any(any(isnan(sn.proc{ist}{r}{1}))) % disabled
                        init_r = 0*ones(1,phases(r));
                    else
                        init_r = State.spaceClosedSingle(phases(r),1);
                    end
                    state = State.decorate(state,init_r);
                end
                space = State.decorate(space,state); %server part
                space = [Inf*ones(size(space,1),1),space]; % attach infinite buffer before servers
            case {SchedStrategy.ID_INF, SchedStrategy.ID_PS, SchedStrategy.ID_DPS, SchedStrategy.ID_GPS}
                % in these policies we only track the jobs in the servers
                for r=1:R
                    init_r = State.spaceClosedSingle(phases(r),n(r));
                    state = State.decorate(state,init_r);
                end
                space = State.decorate(space,state);
            case {SchedStrategy.ID_SIRO, SchedStrategy.ID_LEPT, SchedStrategy.ID_SEPT}
                % in these policies we track an un-ordered buffer and
                % the jobs in the servers
                % build list of job classes in the node, with repetition
                if sum(n) <= S(ist)
                    for r=1:R
                        init_r = State.spaceClosedSingle(phases(r),n(r));
                        state = State.decorate(state,init_r);
                    end
                    space = State.decorate(space,[zeros(size(state,1),R),state]);
                else
                    si = multichoosecon(n,S(ist)); % jobs of class r that are running
                    mi_buf = repmat(n,size(si,1),1) - si; % jobs of class r in buffer
                    for k=1:size(si,1)
                        % determine number of classes r jobs running in phase j
                        kstate=[];
                        for r=1:R
                            init_r = State.spaceClosedSingle(phases(r),si(k,r));
                            kstate = State.decorate(kstate,init_r);
                        end
                        state = [repmat(mi_buf(k,:),size(kstate,1),1), kstate];
                        space = [space; state];
                    end
                end
            case SchedStrategy.ID_LCFSPR
                sizeEstimator = multinomialln(n) - gammaln(sum(n)) + gammaln(1+sn.cap(ist));
                sizeEstimator = round(sizeEstimator/log(10));
                if sizeEstimator > 3
                    if ~isfield(options,'force') || options.force == false
                        %line_warning(mfilename,sprintf('Marginal state space size is in the order of thousands of states. Computation may be slow.',sizeEstimator));
                    end
                end

                if sum(n) == 0
                    space = zeros(1,1+sum(phases)); % unclear if this should 1+sum(K), was sum(K) but State.fromMarginalAndStarted uses 1+sum(K) so was changed here as well
                    return
                end
                % in these policies we track an ordered buffer and
                % the jobs in the servers

                % build list of job classes in the node, with repetition
                vi = [];
                for r=1:R
                    if n(r)>0
                        vi=[vi, r*ones(1,n(r))];
                    end
                end

                % gen permutation of their positions in the waiting buffer
                mi = uniqueperms(vi);
                % now generate server states
                if isempty(mi)
                    mi_buf = zeros(1,max(0,sum(n)-S(ist)));
                    state = zeros(1,R);
                    state = State.decorate(state,[mi_buf,state]);
                else
                    mi = mi(:,(end-min(sum(n),sn.cap(ist))+1):end); % n(r) may count more than once elements within the same chain
                    mi = unique(mi,'rows');
                    % mi_buf: class of job in buffer position i (0=empty)
                    mi_buf = [zeros(size(mi,1),min(sum(n),sn.cap(ist))-S(ist)-size(mi(:,1:end-S(ist)),2)), mi(:,1:end-S(ist))];
                    if isempty(mi_buf)
                        mi_buf = zeros(size(mi,1),1);
                    end
                    mi_buf_kstate = [];
                    %if mi_buf(1)>0
                    % generate job phases for all buffer states
                    %for k=1:size(mi_buf,1)
                    %    mi_buf_kstate(end+1:end+size(bkstate,1),1:size(bkstate,2)) = bkstate;
                    %end
                    %end
                    % mi_srv: class of job running in server i
                    mi_srv = mi(:,max(size(mi,2)-S(ist)+1,1):end);
                    % si: number of class r jobs that are running
                    si =[];
                    for k=1:size(mi_srv,1)                
                        si(k,1:R) = hist(mi_srv(k,:),1:R);
                    end
                    %si = unique(si,'rows');
                    for k=1:size(si,1)
                        % determine number of class r jobs running in phase
                        % j in server state mi_srv(kjs,:) and build
                        % state
                        kstate=[];
                        for r=1:R
                            kstate = State.decorate(kstate,State.spaceClosedSingle(phases(r),si(k,r)));
                        end
                        % generate job phases for all buffer states
                        bkstate = [];
                        for j=mi_buf(k,:) % for each job in the buffer
                            if j>0
                                bkstate = State.decorate(bkstate,[1:phases(j)]');
                            else
                                bkstate = 0;
                            end
                        end
                        bufstate_tmp = State.decorate(mi_buf(k,:), bkstate);
                        % here interleave positions of class and phases in
                        % buf
                        bufstate = zeros(size(bufstate_tmp));
                        bufstate(:,1:2:end)=bufstate_tmp(:,1:size(mi_buf,2));
                        bufstate(:,2:2:end)=bufstate_tmp(:,(size(mi_buf,2)+1):end);
                        state = [state; State.decorate(bufstate, kstate)];
                    end
                end
                space = state;
            case {SchedStrategy.ID_FCFS, SchedStrategy.ID_HOL, SchedStrategy.ID_LCFS}
                sizeEstimator = multinomialln(n) - gammaln(sum(n)) + gammaln(1+sn.cap(ist));
                sizeEstimator = round(sizeEstimator/log(10));
                if sizeEstimator > 3
                    if ~isfield(options,'force') || options.force == false
                        %line_warning(mfilename,sprintf('Marginal state space size is in the order of thousands of states. Computation may be slow.',sizeEstimator));
                    end
                end

                if sum(n) == 0
                    space = zeros(1,1+sum(phases));
                    if sn.nodetype(ind) ~= NodeType.Source
                        for r=1:R
                            switch sn.procid(sn.nodeToStation(ind),r)
                                case {ProcessType.ID_MAP, ProcessType.ID_MMPP2}
                                    space = State.decorate(space, [1:sn.phases(ind,r)]');
                            end
                        end
                    end
                    return
                end
                % in these policies we track an ordered buffer and
                % the jobs in the servers

                % build list of job classes in the node, with repetition
                vi = [];
                for r=1:R
                    if n(r)>0
                        vi=[vi, r*ones(1,n(r))];
                    end
                end

                % gen permutation of their positions in the waiting buffer
                mi = uniqueperms(vi);
                % now generate server states
                if isempty(mi)
                    mi_buf = zeros(1,max(0,sum(n)-S(ist)));
                    state = zeros(1,R);
                    state = State.decorate(state,[mi_buf,state]);
                else
                    mi = mi(:,(end-min(sum(n),sn.cap(ist))+1):end); % n(r) may count more than once elements within the same chain
                    mi = unique(mi,'rows');
                    % mi_buf: class of job in buffer position i (0=empty)
                    mi_buf = [zeros(size(mi,1),min(sum(n),sn.cap(ist))-S(ist)-size(mi(:,1:end-S(ist)),2)), mi(:,1:end-S(ist))];
                    if isempty(mi_buf)
                        mi_buf = zeros(size(mi,1),1);
                    end
                    % mi_srv: class of job running in server i
                    mi_srv = mi(:,max(size(mi,2)-S(ist)+1,1):end);
                    % si: number of class r jobs that are running
                    si =[];
                    for k=1:size(mi_srv,1)
                        si(k,1:R) = hist(mi_srv(k,:),1:R);
                    end
                    %si = unique(si,'rows');
                    for k=1:size(si,1)
                        % determine number of class r jobs running in phase
                        % j in server state mi_srv(k,:) and build
                        % state
                        kstate=[];
                        map_cols = [];

                        for r=1:R
                            init_r = State.spaceClosedSingle(phases(r),si(k,r));
                            if sn.procid(sn.nodeToStation(ind),r) == ProcessType.ID_MAP || sn.procid(sn.nodeToStation(ind),r) == ProcessType.ID_MMPP2
                                if si(k,r) == 0
                                    init_r = State.decorate(init_r, [1:phases(r)]');
                                else
                                    init_r = State.decorate(init_r, 0);
                                end
                                for i=1:size(init_r,1)
                                    if init_r(i,end) == 0
                                        init_r(i,end) = find(init_r(i,:));
                                    end
                                end
                            end
                            kstate = State.decorate(kstate,init_r);
                            if sn.procid(sn.nodeToStation(ind),r) == ProcessType.ID_MAP || sn.procid(sn.nodeToStation(ind),r) == ProcessType.ID_MMPP2
                                map_cols(end+1) = size(kstate,2);
                            end
                        end
                        kstate = kstate(:,[setdiff(1:size(kstate,2),map_cols),map_cols]);
                        state = [state; repmat(mi_buf(k,:),size(kstate,1),1), kstate];
                    end
                end
                space = state;
            case {SchedStrategy.ID_SJF, SchedStrategy.ID_LJF}
                % in these policies the state space includes continuous
                % random variables for the service times
                line_error(mfilename,'The scheduling policy does not admit a discrete state space.\n');
        end
        for r=1:R
            switch sn.routing(ind,r)
                case {RoutingStrategy.ID_RROBIN, RoutingStrategy.ID_WRROBIN}
                    space = State.decorate(space, sn.nodeparam{ind}{r}.outlinks(:));
            end
        end
    case NodeType.Cache
        switch sn.schedid(ist)
            case SchedStrategy.ID_INF
                % in this policies we only track the jobs in the servers
                for r=1:R
                    init_r = State.spaceClosedSingle(phases(r),n(r));
                    state = State.decorate(state,init_r);
                end
                space = State.decorate(space,state);
        end
        for r=1:R
            switch sn.routing(ind,r)
                case RoutingStrategy.ID_RROBIN
                    space = State.decorate(space, sn.nodeparam{ind}{r}.outlinks(:));
            end
        end
end
space = unique(space,'rows'); % do not comment, required to sort empty state as first
space = space(end:-1:1,:); % so that states with jobs in phase 1 comes earlier
end
