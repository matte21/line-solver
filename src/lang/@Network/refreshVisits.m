function [visits, nodevisits] = refreshVisits(self, chains, rt, rtnodes)
% [VISITS, NODEVISITS] = REFRESHCHAINS(CHAINS)

% Copyright (c) 2012-2021, Imperial College London
% All rights reserved.

I = getNumberOfNodes(self);
M = getNumberOfStatefulNodes(self);
K = getNumberOfClasses(self);

refstat = getReferenceStations(self);

for c=1:size(chains,1)
    inchain{c} = find(chains(c,:));
end

for c=1:size(chains,1)
    if sum(refstat(inchain{c}) == refstat(inchain{c}(1))) ~= length(inchain{c})
        refstat(inchain{c}) = refstat(inchain{c}(1));
        %        line_error(mfilename,sprintf('Classes in chain %d have different reference stations. Chain %d classes: %s', c, c, int2str(inchain{c})));
    end
end

%% generate station visits
visits = cell(size(chains,1),1); % visits{c}(i,j) is the number of visits that a chain-c job pays at node i in class j
for c=1:size(chains,1)
    cols = [];
    for i=1:M
        for k=inchain{c}(:)'
            cols(end+1) = (i-1)*K+k;
        end
    end
    Pchain = rt(cols,cols); % routing probability of the chain
    visited = sum(Pchain,2) > 0;
    %                Pchain(visited,visited)
    %                if ~dtmc_isfeasible(Pchain(visited,visited))
    %                    line_error(mfilename,sprintf('The routing matrix in chain %d is not stochastic. Chain %d classes: %s',c, c, int2str(inchain{c})));
    %                end
    alpha_visited = dtmc_solve(Pchain(visited,visited));
    alpha = zeros(1,M*K); alpha(visited) = alpha_visited;
    if max(alpha)>=1-1e-10
        %disabled because a self-looping customer is an absorbing chain
        %line_error(mfilename,'Line:ChainAbsorbingState','One chain has an absorbing state.');
    end
    visits{c} = zeros(M,K);
    for i=1:M
        for k=1:length(inchain{c})
            visits{c}(i,inchain{c}(k)) = alpha((i-1)*length(inchain{c})+k);
        end
    end
    visits{c} = visits{c} / sum(visits{c}(refstat(inchain{c}(1)),inchain{c}));
    visits{c} = abs(visits{c});
end

%% generate node visits
nchains = size(chains,1);
nodevisits = cell(1,nchains);
for c=1:nchains
    nodes_cols = [];
    for i=1:I
        for k=inchain{c}(:)'
            nodes_cols(end+1) = (i-1)*K+k;
        end
    end
    nodes_Pchain = rtnodes(nodes_cols, nodes_cols); % routing probability of the chain
    nodes_visited = sum(nodes_Pchain,2) > 0;
    
    nodes_alpha_visited = dtmc_solve(nodes_Pchain(nodes_visited,nodes_visited));
    nodes_alpha = zeros(1,I); nodes_alpha(nodes_visited) = nodes_alpha_visited;
    nodevisits{c} = zeros(I,K);
    for i=1:I
        for k=1:length(inchain{c})
            nodevisits{c}(i,inchain{c}(k)) = nodes_alpha((i-1)*length(inchain{c})+k);
        end
    end
    nodevisits{c} = nodevisits{c} / sum(nodevisits{c}(refstat(inchain{c}(1)),inchain{c}));
    nodevisits{c}(nodevisits{c}<0) = 0; % remove small numerical perturbations
end
self.sn.visits = nodevisits;

for c=1:self.sn.nchains
    self.sn.visits{c}(isnan(self.sn.visits{c})) = 0;
end

end