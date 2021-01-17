function [nodeStateSpace, sn, capacityc] = spaceGeneratorNodes(sn, cutoff, options)
if nargin<3
    options = Solver.defaultOptions;
end
N = sn.njobs';
sn.space = {};
capacityc = zeros(sn.nnodes, sn.nclasses);
for ind=1:sn.nnodes
    if sn.isstation(ind) % place jobs across stations
        ist = sn.nodeToStation(ind);
        isf = sn.nodeToStateful(ind);
        for r=1:sn.nclasses %cut-off open classes to finite capacity
            c = find(sn.chains(:,r));
            if ~isempty(sn.visits{c}) && sn.visits{c}(ist,r) == 0
                capacityc(ind,r) = 0;
            elseif ~isempty(sn.proc) && ~isempty(sn.proc{ist}{r}) && any(any(isnan(sn.proc{ist}{r}{1}))) % disabled
                capacityc(ind,r) = 0;
            else
                if isinf(N(r))
                    capacityc(ind,r) =  min(cutoff(ist,r), sn.classcap(ist,r));
                else
                    capacityc(ind,r) =  sum(sn.njobs(sn.chains(c,:)));
                end
            end
        end
        sn.space{isf} = State.fromMarginalBounds(sn, ind, [], capacityc(ind,:), sn.cap(ist), options);
        if isinf(sn.nservers(ist))
            sn.nservers(ist) = sum(capacityc(ind,:));
        end
    elseif sn.isstateful(ind) % generate state space of other stateful nodes that are not stations
        %ist = sn.nodeToStation(ind);
        isf = sn.nodeToStateful(ind);
        switch sn.nodetype(ind)
            case NodeType.Cache
                for r=1:sn.nclasses % restrict state space generation to immediate events
                    if isnan(sn.varsparam{ind}.pref{r})
                        capacityc(ind,r) =  1; %
                    else
                        capacityc(ind,r) =  1; %
                    end
                end
            otherwise
                capacityc(ind,:) =  1; %
        end
        state_var = State.spaceLocalVars(sn, ind);
        state_bufsrv = State.fromMarginalBounds(sn, ind, [], capacityc(ind,:), 1, options);
        sn.space{isf} = State.decorate(state_bufsrv,state_var); % generate all possible states for local variables
    end
end
nodeStateSpace = sn.space;
end