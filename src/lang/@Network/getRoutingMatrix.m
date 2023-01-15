function [rt,rtnodes,conn,chains,rtNodesByClass,rtNodesByStation] = getRoutingMatrix(self, arvRates)
% [RT,RTNODES,CONNMATRIX,CHAINS,RTNODESBYCLASS,RTNODESBYSTATION] = GETROUTINGMATRIX(ARVRATES)

% Copyright (c) 2012-2023, Imperial College London
% All rights reserved.

if self.hasStruct
    sn = self.sn;
    idxSource = find(sn.nodetype == NodeType.ID_SOURCE);
    idxSink = find(sn.nodetype == NodeType.ID_SINK);
    indexOpenClasses = find(isinf(sn.njobs));
    hasOpen = ~isempty(indexOpenClasses);
    if nargin<2
        arvRates = sn.rates(sn.nodeToStation(idxSource),indexOpenClasses);
    end
    nodes = self.nodes;
    conn = sn.connmatrix;
    I = sn.nnodes;
    K = sn.nclasses;
    NK = sn.njobs;
    statefulNodes = find(sn.isstateful)';
else
    sn = self.sn;
    idxSource = self.getIndexSourceNode;
    idxSink = self.getIndexSinkNode;
    indexOpenClasses = self.getIndexOpenClasses;
    nodes = self.nodes;

    conn = self.getConnectionMatrix;
    sn.connmatrix = conn;
    hasOpen = hasOpenClasses(self);

    I = self.getNumberOfNodes;
    K = self.getNumberOfClasses;
    NK = self.getNumberOfJobs;
    for ind=1:I
        for k=1:K
            if isempty(self.nodes{ind}.output.outputStrategy{k})
                sn.routing(ind,k) = RoutingStrategy.ID_DISABLED;
            else
                sn.routing(ind,k) = RoutingStrategy.toId(nodes{ind}.output.outputStrategy{k}{2});
            end
        end
    end
    statefulNodes = self.getIndexStatefulNodes;
end

rtnodes = zeros(I*K);
rtNodesByClass = {};
rtNodesByStation = {};
% The first loop considers the class at which a job enters the
% target station
for ind=1:I
    node_i = nodes{ind};
    outputStrategy = node_i.output.outputStrategy;
    switch class(node_i.output)
        case 'Forker'
            for jnd=1:I
                for k=1:K
                    if conn(ind,jnd)>0                      
                        if length(node_i.output.outputStrategy{k})>=3
                            fanout = length(node_i.output.outputStrategy{k}{3});
                        else
                            fanout = 1;
                        end
                        rtnodes((ind-1)*K+k,(jnd-1)*K+k)=1.0/fanout;
                        outputStrategy_k = outputStrategy{k};
                        switch sn.routing(ind,k)
                            case RoutingStrategy.ID_PROB
                                if length(outputStrategy_k{end}) ~= sum(conn(ind,:))
                                    line_error(mfilename,'Fork must have 1.0 routing probability towards all outgoing links.');
                                end
                                for t=1:length(outputStrategy_k{end}) % for all outgoing links
                                    if outputStrategy_k{end}{t}{2} ~= 1.0
                                        line_error(mfilename,sprintf('Fork must have 1.0 routing probability towards all outgoing links, but a routing probability is at %f.',outputStrategy_k{end}{t}{2}));
                                    end
                                end
                        end
                    end
                end
            end
        otherwise
            isSink_i = isa(node_i,'Sink');
            for k=1:K
                outputStrategy_k = outputStrategy{k};
                switch sn.routing(ind,k)
                    case RoutingStrategy.ID_PROB
                        if isinf(NK(k)) || ~isSink_i
                            for t=1:length(outputStrategy_k{end}) % for all outgoing links
                                jnd = outputStrategy_k{end}{t}{1}.index;
                                rtnodes((ind-1)*K+k,(jnd-1)*K+k) = outputStrategy_k{end}{t}{2};
                            end
                        end
                    case RoutingStrategy.ID_DISABLED
                        % we set this to be non-zero as otherwise the
                        % classes that do not visit a class switch are
                        % misconfigured in JMT
                        for jnd=1:I
                            if conn(ind,jnd)>0
                                rtnodes((ind-1)*K+k,(jnd-1)*K+k) = 1/sum(conn(ind,:));
                            end
                        end
                    case {RoutingStrategy.ID_RAND, RoutingStrategy.ID_RROBIN, RoutingStrategy.ID_WRROBIN, RoutingStrategy.ID_JSQ}
                        if isinf(NK(k)) % open class
                            for jnd=1:I
                                if conn(ind,jnd)>0
                                    rtnodes((ind-1)*K+k,(jnd-1)*K+k)=1/sum(conn(ind,:));
                                end
                            end
                        elseif ~isa(node_i,'Source') && ~isSink_i % don't route closed classes out of source nodes
                            connectionsClosed = conn;
                            if connectionsClosed(ind,idxSink)
                                connectionsClosed(ind,idxSink) = 0;
                            end
                            for jnd=1:I
                                if connectionsClosed(ind,jnd)>0
                                    rtnodes((ind-1)*K+k,(jnd-1)*K+k)=1/(sum(connectionsClosed(ind,:)));
                                end
                            end
                        end
                    otherwise
                        for jnd=1:I
                            if conn(ind,jnd)>0
                                rtnodes((ind-1)*K+k,(jnd-1)*K+k) = GlobalConstants.FineTol;
                            end
                        end
                        %line_error([outputStrategy_k{2},' routing policy is not yet supported.']);
                end
            end
    end
end

% The second loop corrects the first one at nodes that change
% the class of the job in the service section.
for ind=1:I % source
    if isa(nodes{ind}.server,'StatelessClassSwitcher')
        Pi = rtnodes(((ind-1)*K+1):ind*K,:);
        Pcs = nodes{ind}.server.csFun(1:K,1:K);
        rtnodes(((ind-1)*K+1):ind*K,:) = 0;
        for jnd=1:I % destination
            Pij = Pi(:,((jnd-1)*K+1):jnd*K); %Pij(r,s)
            % Find the routing probability section determined by the router section in the first loop
            rtnodes(((ind-1)*K+1) : ((ind-1)*K+K),(jnd-1)*K+(1:K)) = Pcs.*repmat(diag(Pij)',K,1);
        end
    elseif isa(nodes{ind}.server,'StatefulClassSwitcher')
        Pi = rtnodes(((ind-1)*K+1):ind*K,:);
        for r=1:K
            for s=1:K
                Pcs(r,s) = nodes{ind}.server.csFun(r,s,[],[]); % get csmask
            end
        end
        rtnodes(((ind-1)*K+1):ind*K,:) = 0;
        if isa(nodes{ind}.server,'CacheClassSwitcher')
            for r=1:K
                if (isempty(find(r == nodes{ind}.server.hitClass)) && isempty(find(r == nodes{ind}.server.missClass)))
                    Pcs(r,:) = Pcs(r,:)/sum(Pcs(r,:));
                end
            end

            for r=1:K
                if (isempty(find(r == nodes{ind}.server.hitClass)) && isempty(find(r == nodes{ind}.server.missClass)))
                    for jnd=1:I % destination
                        for s=1:K
                            Pi((ind-1)*K+r,(jnd-1)*K+s) = 0;
                        end
                    end
                end
            end

            for r=1:K
                if length(nodes{ind}.server.actualHitProb)>=r && length(nodes{ind}.server.hitClass)>=r
                    ph = nodes{ind}.server.actualHitProb(r);
                    pm = nodes{ind}.server.actualMissProb(r);
                    h = nodes{ind}.server.hitClass(r);
                    m = nodes{ind}.server.missClass(r);
                    rtnodes((ind-1)*K+r,(ind-1)*K+h) = ph;
                    rtnodes((ind-1)*K+r,(ind-1)*K+m) = pm;
                else
                    if length(nodes{ind}.server.hitClass)>=r
                        h = nodes{ind}.server.hitClass(r);
                        m = nodes{ind}.server.missClass(r);
                        rtnodes((ind-1)*K+r,(ind-1)*K+h) = NaN;
                        rtnodes((ind-1)*K+r,(ind-1)*K+m) = NaN;
                    end
                end
            end

            for jnd=1:I % destination
                Pij = Pi(1:K,((jnd-1)*K+1):jnd*K); %Pij(r,s)
                for r=1:K
                    if ~(isempty(find(r == nodes{ind}.server.hitClass)) && isempty(find(r == nodes{ind}.server.missClass)))
                        for s=1:K
                            % Find the routing probability section determined by the router section in the first loop
                            %Pnodes(((i-1)*K+1):i*K,((j-1)*K+1):j*K) = Pcs*Pij;
                            rtnodes((ind-1)*K+r,(jnd-1)*K+s) = Pcs(r,s)*Pij(s,s);
                        end
                    end
                end
            end
        end
    end
end

% ignore all chains containing a Pnodes column that sums to 0,
% since these are classes that cannot arrive to the node
% unless this column belongs to the source
colsToIgnore = find(sum(rtnodes,1)==0);
if hasOpen
    colsToIgnore = setdiff(colsToIgnore,(idxSource-1)*K+(1:K));
end

% We route back from the sink to the source. Since open classes
% have an infinite population, if there is a class switch QN
% with the following chains
% Source -> (A or B) -> C -> Sink
% Source -> D -> Sink
% We can re-route class C into the source either as A or B or C.
% We here re-route back as C and leave for the chain analyzer
% to detect that C is in a chain with A and B and change this
% part.

csmask = self.csmatrix;
if isempty(csmask) % models not built with link(P)
    [C,WCC]=weaklyconncomp(rtnodes+rtnodes');
    WCC(colsToIgnore) = 0;
    chainCandidates = cell(1,C);
    for r=1:C
        chainCandidates{r} = find(WCC==r);
    end

    chains = false(length(chainCandidates),K); % columns are classes, rows are chains
    tmax = 0;
    for t=1:length(chainCandidates)
        if length(chainCandidates{t})>1
            tmax = tmax+1;
            chains(tmax,(mod(chainCandidates{t}-1,K)+1))=true;
        end
    end
    chains(tmax+1:end,:)=[];
else % this is faster since csmask is smaller than rtnodes
    [C,WCC] = weaklyconncomp(csmask+csmask');

    chainCandidates = cell(1,C);
    for c=1:C
        chainCandidates{c} = find(WCC==c);
    end

    chains = false(length(chainCandidates),K);
    for t=1:length(chainCandidates)
        chains(t,chainCandidates{t}) = true;
    end
end

chains = unique(chains,'rows');
try
    chains = sortrows(chains,'descend');
catch % old MATLABs
    chains = sortrows(chains);
end

% overlapping chains can occur if a class that enters in a Cache
% reappars downhill in the network in rtnodes in that case we merge
% the two chains
splitChains = [];
for col=find(sum(chains,1)>1)
    rows = find(chains(:,col));
    for r=rows(2:end)'
        chains(rows(1),:) = chains(rows(1),:) | chains(r,:);
        splitChains(end+1)=r;
    end
end
chains(splitChains,:)=[];

% We now obtain the routing matrix P by ignoring the non-stateful
% nodes and calculating by the stochastic complement method the
% correct transition probabilities, that includes the effects
% of the non-stateful nodes (e.g., ClassSwitch)
statefulNodesClasses = [];
for ind=statefulNodes %#ok<FXSET>
    statefulNodesClasses(end+1:end+K)= ((ind-1)*K+1):(ind*K);
end

% this routes open classes back from the sink into the source
% it will not work with non-renewal arrivals as it choses in which open
% class to reroute a job with probability depending on the arrival rates
if hasOpen
    arvRates(isnan(arvRates)) = 0;
    for s=indexOpenClasses
        s_chain = find(chains(:,s));
        others_in_chain = find(chains(s_chain,:)); %#ok<FNDSB>
        rtnodes((idxSink-1)*K+others_in_chain,(idxSource-1)*K+others_in_chain) = repmat(arvRates(others_in_chain)/sum(arvRates(others_in_chain)),length(others_in_chain),1);
    end
end

%% Hide the nodes that are not stateful
rt = dtmc_stochcomp(rtnodes,statefulNodesClasses);
% verify irreducibility
% disabled as it casts warning in many models that are seemingly fine
%try
%    eigen = eig(rt); % exception if rt has NaN or Inf
%    if sum(eigen>=1)>1
%        line_warning(mfilename, 'Solutions may be invalid, the routing matrix is reducible. The path of two or more classes form independent non-interacting models.');
%    end
%end
sn.rt = rt;
sn.chains = chains;
self.sn = sn;

%% Compute optional outputs
if nargout >= 5
    rtNodesByClass = cellzeros(K,K,I,I);
    for ind=1:I
        for jnd=1:I
            for r=1:K
                for s=1:K
                    rtNodesByClass{s,r}(ind,jnd) = rtnodes((ind-1)*K+s,(jnd-1)*K+r);
                end
            end
        end
    end
end

if nargout >= 6
    rtNodesByStation = cellzeros(I,I,K,K);
    for ind=1:I %#ok<FXSET>
        for jnd=1:I
            for r=1:K
                for s=1:K
                    rtNodesByStation{ind,jnd}(r,s) = rtnodes((ind-1)*K+s,(jnd-1)*K+r);
                end
            end
        end
    end
end
end