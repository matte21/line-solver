function [rt,rtNodes,connections,rtNodesByClass,rtNodesByStation] = getRoutingMatrix(self, arvRates)
% [RT,RTNODES,CONNMATRIX,RTNODESBYCLASS,RTNODESBYSTATION] = GETROUTINGMATRIX(ARVRATES)

% Copyright (c) 2012-2022, Imperial College London
% All rights reserved.

if nargin<2 %~exist('arvRates','var')
    for r=self.getIndexOpenClasses
        arvRates(r) = 1 / self.getSource.input.sourceClasses{r}{end}.getMean;
    end
end
nodes = self.nodes;

%nodeNames = getNodeNames(self);
% connection matrix
connections = self.getConnectionMatrix;
self.sn.connmatrix = connections;
rtNodesByClass = {};
rtNodesByStation = {};
hasOpen = hasOpenClasses(self);

I = self.getNumberOfNodes;
K = self.getNumberOfClasses;
NK = self.getNumberOfJobs;
rtNodes = zeros(I*K);
% The first loop considers the class at which a job enters the
% target station
for ind=1:I
    node_i = nodes{ind};
    switch class(node_i.output)
        case 'Forker'
            for jnd=1:I
                for k=1:K
                    if connections(ind,jnd)>0
                        rtNodes((ind-1)*K+k,(jnd-1)*K+k)=1.0;
                        outputStrategy_k = node_i.output.outputStrategy{k};
                        switch outputStrategy_k{2}
                            case RoutingStrategy.PROB
                                if length(outputStrategy_k{end}) ~= sum(connections(ind,:))
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
                outputStrategy_k = node_i.output.outputStrategy{k};
                switch outputStrategy_k{2}
                    case RoutingStrategy.PROB
                        if isinf(NK(k)) || ~isSink_i
                            for t=1:length(outputStrategy_k{end}) % for all outgoing links
                                %j = findstring(nodeNames, outputStrategy_k{end}{t}{1}.name);
                                jnd = outputStrategy_k{end}{t}{1}.index;
                                rtNodes((ind-1)*K+k,(jnd-1)*K+k) = outputStrategy_k{end}{t}{2};
                            end
                        end
                    case RoutingStrategy.DISABLED
                        % we set this to be non-zero as otherwise the
                        % classes that do not visit a class switch are
                        % misconfigured in JMT
                        for jnd=1:I
                            if connections(ind,jnd)>0
                               rtNodes((ind-1)*K+k,(jnd-1)*K+k) = 1/sum(connections(ind,:)); 
                            end
                        end
                    case {RoutingStrategy.RAND, RoutingStrategy.RROBIN, RoutingStrategy.WRROBIN, RoutingStrategy.JSQ}
                        if isinf(NK(k)) % open class
                            for jnd=1:I
                                if connections(ind,jnd)>0
                                    rtNodes((ind-1)*K+k,(jnd-1)*K+k)=1/sum(connections(ind,:));
                                end
                            end
                        elseif ~isa(node_i,'Source') && ~isSink_i % don't route closed classes out of source nodes
                            connectionsClosed = connections;
                            if connectionsClosed(ind,self.getNodeIndex(self.getSink))
                                connectionsClosed(ind,self.getNodeIndex(self.getSink)) = 0;
                            end
                            for jnd=1:I
                                if connectionsClosed(ind,jnd)>0
                                    rtNodes((ind-1)*K+k,(jnd-1)*K+k)=1/(sum(connectionsClosed(ind,:)));
                                end
                            end
                        end
                    otherwise
                        for jnd=1:I
                            if connections(ind,jnd)>0
                                rtNodes((ind-1)*K+k,(jnd-1)*K+k) = Distrib.Zero;
                            end
                        end
                        %line_error([outputStrategy_k{2},' routing policy is not yet supported.']);
                end
            end
    end
end

% The second loop corrects the first one at nodes that change
% the class of the job in the service section.


for ind=1:self.getNumberOfNodes % source
    if isa(nodes{ind}.server,'StatelessClassSwitcher')
        Pi = rtNodes(((ind-1)*K+1):ind*K,:);        
        Pcs = nodes{ind}.server.csFun(1:K,1:K);
        rtNodes(((ind-1)*K+1):ind*K,:) = 0;
        for jnd=1:I % destination
            Pij = Pi(:,((jnd-1)*K+1):jnd*K); %Pij(r,s)
            % Find the routing probability section determined by the router section in the first loop
            rtNodes(((ind-1)*K+1) : ((ind-1)*K+K),(jnd-1)*K+(1:K)) = Pcs.*repmat(diag(Pij)',K,1);
        end
    elseif isa(nodes{ind}.server,'StatefulClassSwitcher')
        Pi = rtNodes(((ind-1)*K+1):ind*K,:);
        for r=1:K
            for s=1:K
                Pcs(r,s) = nodes{ind}.server.csFun(r,s,[],[]); % get csmask
            end
        end
        rtNodes(((ind-1)*K+1):ind*K,:) = 0;
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
                    rtNodes((ind-1)*K+r,(ind-1)*K+h) = ph;
                    rtNodes((ind-1)*K+r,(ind-1)*K+m) = pm;
                else
                    if length(nodes{ind}.server.hitClass)>=r
                        h = nodes{ind}.server.hitClass(r);
                        m = nodes{ind}.server.missClass(r);
                        rtNodes((ind-1)*K+r,(ind-1)*K+h) = NaN;
                        rtNodes((ind-1)*K+r,(ind-1)*K+m) = NaN;
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
                            rtNodes((ind-1)*K+r,(jnd-1)*K+s) = Pcs(r,s)*Pij(s,s);
                        end
                    end
                end
            end
        end
    end
    
    % ignore all chains containing a Pnodes column that sums to 0,
    % since these are classes that cannot arrive to the node
    % unless this column belongs to the source
    colsToIgnore = find(sum(rtNodes,1)==0);
    if hasOpen
        idxSource = self.getIndexSourceNode;
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
    
    [C,inChain]=weaklyconncomp(rtNodes+rtNodes');
    inChain(colsToIgnore) = 0;
    chainCandidates = cell(1,C);
    for r=1:C
        chainCandidates{r} = find(inChain==r);
    end
    
    chainsPnodes = []; % columns are classes? rows are definitely chains
    for t=1:length(chainCandidates)
        if length(chainCandidates{t})>1
            %chainsPnodes(end+1,unique(mod(chainCandidates{t}-1,K)+1))=1;
            chainsPnodes(end+1,(mod(chainCandidates{t}-1,K)+1))=1;
        end
    end
    try
        chainsPnodes = sortrows(chainsPnodes,'descend');
    catch % old MATLABs
        chainsPnodes = sortrows(chainsPnodes);
    end
    % this routes open classes back from the sink into the source
    % it will not work with non-renewal arrivals as it choses in which open
    % class to reroute a job with probability depending on the arrival rates
    if hasOpen
        arvRates(isnan(arvRates)) = 0;
        idxSink = self.getIndexSinkNode;
        for s=self.getIndexOpenClasses
            s_chain = find(chainsPnodes(:,s));
            others_in_chain = find(chainsPnodes(s_chain,:));
            rtNodes((idxSink-1)*K+others_in_chain,(idxSource-1)*K+others_in_chain) = repmat(arvRates(others_in_chain)/sum(arvRates(others_in_chain)),length(others_in_chain),1);
        end
    end
    
    % We now obtain the routing matrix P by ignoring the non-stateful
    % nodes and calculating by the stochastic complement method the
    % correct transition probabilities, that includes the effects
    % of the non-stateful nodes (e.g., ClassSwitch)
    statefulNodesClasses = [];
    for ind=getIndexStatefulNodes(self)
        statefulNodesClasses(end+1:end+K)= ((ind-1)*K+1):(ind*K);
    end
    
    % Hide the nodes that are not stateful
    rt = dtmc_stochcomp(rtNodes,statefulNodesClasses);
    if nargout >= 4
        rtNodesByClass = cellzeros(K,K,I,I);
        for ind=1:I
            for jnd=1:I
                for r=1:K
                    for s=1:K
                        rtNodesByClass{s,r}(ind,jnd) = rtNodes((ind-1)*K+s,(jnd-1)*K+r);
                    end
                end
            end
        end
    end
    
    % verify irreducibility

    try
        eigen = eig(rt); % exception if rt has NaN or Inf
        if sum(eigen>=1)>1
            line_warning(mfilename, 'Solutions may be invalid, the routing matrix is reducible. The path of two or more classes form independent non-interacting models.');
        end
    end
    
    %
    if nargout >= 5
        rtNodesByStation = cellzeros(I,I,K,K);
        for ind=1:I
            for jnd=1:I
                for r=1:K
                    for s=1:K
                        rtNodesByStation{ind,jnd}(r,s) = rtNodes((ind-1)*K+s,(jnd-1)*K+r);
                    end
                end
            end
        end
    end
end