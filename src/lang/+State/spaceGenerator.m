function [SS,SSh,sn] = spaceGenerator(sn, cutoff, options)
% [SS,SSH,QN] = SPACEGENERATOR(QN, CUTOFF)

% Copyright (c) 2012-2023, Imperial College London
% All rights reserved.

% State space generator
% SS: state space
% SSh: hashed state space
% sn: updated sn
N = sn.njobs';
Np = N;

if ~exist('cutoff','var') && any(isinf(Np)) % if the model has open classes
    line_error(mfilename,'Unspecified cutoff for open classes in state space generator.');
end

if numel(cutoff)==1
    cutoff = cutoff * ones(sn.nstations, sn.nclasses);
end

[~, sn, capacityc] = State.spaceGeneratorNodes(sn, cutoff, options);

%%
isOpenClass = isinf(Np);
isClosedClass = ~isOpenClass;
for r=1:sn.nclasses %cut-off open classes to finite capacity
    if isOpenClass(r)
        Np(r) = max(capacityc(:,r)); % if replaced by sum stateMarg_i can exceed capacity
    end
end

nstatefulp = sn.nstateful - sum(sn.nodetype == NodeType.Source); % M without sources
n = pprod(Np);
chainStationPos=[];
%J = zeros(1,Mns*R);
%n = pprod(n,Np);
while n>=0
    % this is rather inefficient since n ignores chains and thus it can
    % generated state spaces such as
    %   J =
    %
    %      0     0     0     0
    %      0     0     0     1
    %      0     0     1     0
    %      0     1     0     0
    %      1     0     0     0
    %      0     0     0     1
    %      0     0     1     0
    %      0     1     0     0
    %      1     0     0     0
    %      0     0     0     2
    %      0     0     1     1
    %      0     0     2     0
    %      0     1     0     1
    %      1     0     0     1
    %      0     1     1     0
    %      1     0     1     0
    %      0     2     0     0
    %      1     1     0     0
    %      2     0     0     0
    % that are then in the need for a call to unique
    if all(isOpenClass) | (Np(isClosedClass) == n(isClosedClass)) %#ok<OR2> 
        chainStationPos = [chainStationPos; State.spaceClosedMultiCS(nstatefulp,n,sn.chains)];
    end
    n = pprod(n,Np);
end
chainStationPos = unique(chainStationPos,'rows');

netstates = cell(size(chainStationPos,1), sn.nstateful);
for j=1:size(chainStationPos,1)
    for ind=1:sn.nnodes
        if sn.nodetype(ind) == NodeType.Source
            isf = sn.nodeToStateful(ind);
            state_i = State.fromMarginal(sn,ind,[]);
            netstates{j,isf} = State.getHash(sn,ind,state_i);
        elseif sn.isstation(ind)
            isf = sn.nodeToStateful(ind);
            stateMarg_i = chainStationPos(j,(isf-sum(sn.nodetype(1:ind-1) == NodeType.Source)):nstatefulp:end);
            if any(stateMarg_i > capacityc(ind,:))
                netstates{j,isf} = State.getHash(sn,ind,[]);
            else
                state_i = State.fromMarginal(sn,ind,stateMarg_i);
                netstates{j,isf} = State.getHash(sn,ind,state_i);
            end
        elseif sn.isstateful(ind)
            isf = sn.nodeToStateful(ind);
            stateMarg_i = chainStationPos(j,(isf-sum(sn.nodetype(1:ind-1) == NodeType.Source)):nstatefulp:end);
            state_i = sn.space{isf};
            if any(stateMarg_i > capacityc(ind,:))
                netstates{j,isf} = State.getHash(sn,ind,[]);
            elseif sn.nodetype(ind) == NodeType.Cache                
                cacheClasses = union(sn.nodeparam{ind}.hitclass, sn.nodeparam{ind}.missclass);
                %if sum(stateMarg_i(cacheClasses)) > 1 || sum(stateMarg_i(setdiff(1:sn.nclasses,cacheClasses))) > 0                                        
                if sum(stateMarg_i(1:sn.nclasses)) > 1
                    netstates{j,isf} = State.getHash(sn,ind,[]);
                else
                    state_i = state_i(findrows(state_i(:,1:length(stateMarg_i)),stateMarg_i),:);
                    netstates{j,isf} = State.getHash(sn,ind,state_i);
                end
            else
                state_i = state_i(findrows(state_i(:,1:length(stateMarg_i)),stateMarg_i),:);
                netstates{j,isf} = State.getHash(sn,ind,state_i);
            end
        end
    end
end

ctr = 0;
%SS = sparse([]);
SS = [];
SSh = [];
for j=1:size(chainStationPos,1)
    % for each network state
    v = {netstates{j,:}};
    % cycle over lattice
    vN = cellfun(@length,v)-1;
    n = pprod(vN);
    while n >=0
        u={}; h={};
        skip = false;
        for isf=1:length(n)
            h{isf} = v{isf}(1+n(isf));
            if h{isf} < 0
                skip = true;
                break
            end
            u{isf} = sn.space{isf}(v{isf}(1+n(isf)),:);
        end
        if skip == false
            ctr = ctr + 1; % do not move
            SS(ctr,:)=cell2mat(u);
            SSh(ctr,:)=cell2mat(h);
        end
        n = pprod(n,vN);
    end
end
[SS,IA] = unique(SS,'rows');
SSh = SSh(IA,:);
end
