function space = fromMarginal(sn, ind, n, options)
% SPACE = FROMMARGINAL(QN, IND, N, OPTIONS)

% Copyright (c) 2012-2021, Imperial College London
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

% ind: node index
ist = sn.nodeToStation(ind);
isf = sn.nodeToStateful(ind);

if sn.isstateful(ind) && ~sn.isstation(ind)
    for r=1:R
        init = State.spaceClosedSingle(1,n(r));
        state = State.decorate(state,init);
    end
    space = State.decorate(space,state);
    return
end

K = zeros(1,R);
for r=1:R
    if isempty(sn.proc{ist}{r})
        K(r) = 0;
    else
        K(r) = length(sn.proc{ist}{r}{1});
    end
end
if (sn.schedid(ist) ~= SchedStrategy.ID_EXT) && any(n>sn.classcap(ist,:))
    return
end

% generate local-state space
switch sn.nodetype(ind)
    case {NodeType.Queue, NodeType.Delay, NodeType.Source}
        switch sn.schedid(ist)
            case SchedStrategy.ID_EXT
                for r=1:R
                    if ~isempty(sn.proc) && ~isempty(sn.proc{ist}{r}) && any(any(isnan(sn.proc{ist}{r}{1}))) % disabled
                        init = 0*ones(1,K(r));
                    else
                        init = State.spaceClosedSingle(K(r),1);
                    end
                    state = State.decorate(state,init);
                end
                space = State.decorate(space,state);
                space = [Inf*ones(size(space,1),1),space];
            case {SchedStrategy.ID_INF, SchedStrategy.ID_PS, SchedStrategy.ID_DPS, SchedStrategy.ID_GPS}
                % in these policies we only track the jobs in the servers
                for r=1:R
                    init = State.spaceClosedSingle(K(r),n(r));
                    state = State.decorate(state,init);
                end
                space = State.decorate(space,state);
            case {SchedStrategy.ID_SIRO, SchedStrategy.ID_LEPT, SchedStrategy.ID_SEPT}
                % in these policies we track an un-ordered buffer and
                % the jobs in the servers
                % build list of job classes in the node, with repetition
                if sum(n) <= S(ist)
                    for r=1:R
                        init = State.spaceClosedSingle(K(r),n(r));
                        state = State.decorate(state,init);
                    end
                    space = State.decorate(space,[zeros(size(state,1),R),state]);
                else
                    si = multichoosecon(n,S(ist)); % jobs of class r that are running
                    mi_buf = repmat(n,size(si,1),1) - si; % jobs of class r in buffer
                    for k=1:size(si,1)
                        % determine number of classes r jobs running in phase j
                        kstate=[];
                        for r=1:R
                            init = State.spaceClosedSingle(K(r),si(k,r));
                            kstate = State.decorate(kstate,init);
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
                    space = zeros(1,1+sum(K)); % unclear if this should 1+sum(K), was sum(K) but State.fromMarginalAndStarted uses 1+sum(K) so was changed here as well
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
                            kstate = State.decorate(kstate,State.spaceClosedSingle(K(r),si(k,r)));
                        end
                        % generate job phases for all buffer states
                        bkstate = [];
                        for j=mi_buf(k,:) % for each job in the buffer
                            if j>0
                                bkstate = State.decorate(bkstate,[1:K(j)]');
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
                    space = zeros(1,1+sum(K)); % unclear if this should 1+sum(K), was sum(K) but State.fromMarginalAndStarted uses 1+sum(K) so was changed here as well
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
                        % j in server state mi_srv(kjs,:) and build
                        % state
                        kstate=[];
                        for r=1:R
                            kstate = State.decorate(kstate,State.spaceClosedSingle(K(r),si(k,r)));
                        end
                        state = [state; repmat(mi_buf(k,:),size(kstate,1),1), kstate];
                    end
                end
                space = state;                
            case {SchedStrategy.ID_SJF, SchedStrategy.ID_LJF}
                % in these policies the state space includes continuous
                % random variables for the service times
                line_error(mfilename,'The scheduling policy does not admit a discrete state space.\n');
        end
        switch sn.routing(ind)
            case RoutingStrategy.ID_RROBIN
                space = State.decorate(space, sn.varsparam{ind}.outlinks(:));
        end
    case NodeType.Cache
        switch sn.schedid(ist)
            case SchedStrategy.ID_INF
                % in this policies we only track the jobs in the servers
                for r=1:R
                    init = State.spaceClosedSingle(K(r),n(r));
                    state = State.decorate(state,init);
                end
                space = State.decorate(space,state);
        end
        switch sn.routing(ind)
            case RoutingStrategy.ID_RROBIN
                space = State.decorate(space, sn.varsparam{ind}.outlinks(:));
        end
end
space = unique(space,'rows'); % do not comment, required to sort empty state as first
space = space(end:-1:1,:); % so that states with jobs in phase 1 comes earlier
end
