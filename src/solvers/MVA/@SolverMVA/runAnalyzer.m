function [runtime, analyzer] = runAnalyzer(self, options)
% RUNTIME = RUN()
% Run the solver

T0=tic;
if nargin<2
    options = self.getOptions;
end

QN = []; UN = [];
RN = []; TN = [];
CN = []; XN = [];
lG = NaN;

if self.enableChecks && ~self.supports(self.model)
    ME = MException('Line:FeatureNotSupportedBySolver', 'This model contains features not supported by the solver.');
    throw(ME);
end

Solver.resetRandomGeneratorSeed(options.seed);

sn = getStruct(self); % doesn't need initial state

if (strcmp(options.method,'exact')||strcmp(options.method,'mva')) && ~self.model.hasProductFormSolution
    line_error(mfilename,'The exact method requires the model to have a product-form solution. This model does not have one. You can use Network.hasProductFormSolution() to check before running the solver.');
end

method = options.method;

if sn.nclasses==1 && sn.nclosedjobs == 0 && length(sn.nodetype)==3 && all(sort(sn.nodetype)' == sort([NodeType.Source,NodeType.Queue,NodeType.Sink])) % is an open queueing system
    [QN,UN,RN,TN,CN,XN,lG,runtime] = solver_mva_qsys_analyzer(sn, options);
    if nargout > 1
        analyzer = @(sn) solver_mva_qsys_analyzer(sn, options);
    end
elseif sn.nclosedjobs == 0 && length(sn.nodetype)==3 && all(sort(sn.nodetype)' == sort([NodeType.Source,NodeType.Cache,NodeType.Sink])) % is a non-rentrant cache
    % random initialization
    for ind = 1:sn.nnodes
        if sn.nodetype(ind) == NodeType.Cache
            prob = self.model.nodes{ind}.server.hitClass;
            prob(prob>0) = 0.5;
            self.model.nodes{ind}.setResultHitProb(prob);
            self.model.nodes{ind}.setResultMissProb(1-prob);
        end
    end
    self.model.refreshChains();
    % start iteration
    [QN,UN,RN,TN,CN,XN,lG,runtime] = solver_mva_cache_analyzer(sn, options);
    if nargout > 1
        analyzer = @(sn) solver_mva_cache_analyzer(sn, options);
    end
    
    for ind = 1:sn.nnodes
        if sn.nodetype(ind) == NodeType.Cache
            %prob = self.model.nodes{ind}.server.hitClass;
            %prob(prob>0) = 0.5;
            hitClass = self.model.nodes{ind}.getHitClass;
            missClass = self.model.nodes{ind}.getMissClass;
            hitprob = zeros(1,length(hitClass));
            for k=1:length(self.model.nodes{ind}.getHitClass)
                %                for k=1:length(self.model.nodes{ind}.server.hitClass)
                chain_k = sn.chains(:,k)>0;
                inchain = sn.chains(chain_k,:)>0;
                h = hitClass(k);
                m = missClass(k);
                if h>0 && m>0
                    hitprob(k) = XN(h) / nansum(XN(inchain));
                end
            end
            self.model.nodes{ind}.setResultHitProb(hitprob);
            self.model.nodes{ind}.setResultMissProb(1-hitprob);
        end
    end
    self.model.refreshChains;
else % queueing network
    if any(sn.nodetype == NodeType.Cache)
        options = Solver.defaultOptions;
        lambda = zeros(1,self.model.getNumberOfClasses);
        lambda_1 = zeros(1,self.model.getNumberOfClasses);
        for it=1:options.iter_max
            
            %Porig = model.getLinkedRoutingMatrix;
            [~,Pnodes] = self.model.getRoutingMatrix;
            %model.resetNetwork; % Remove artificial class switch nodes
            staticmodel = Network('staticmodel');
            for ind=1:self.model.getNumberOfNodes
                switch class(self.model.nodes{ind})
                    case 'Cache'
                        Pcs = zeros(self.model.getNumberOfClasses);
                        hitClass = full(self.model.nodes{ind}.getHitClass);
                        missClass = full(self.model.nodes{ind}.getMissClass);
                        if it == 1
                            % initial random value of arrival rates lambda to the
                            % cache
                            for r=1:length(self.model.nodes{ind}.server.inputJobClasses)
                                if ~isempty(self.model.nodes{ind}.server.inputJobClasses{r})
                                    lambda_1(r) = rand;
                                end
                            end
                            lambda(r)=lambda_1(r);
                       end

                        % solution of isolated cache
                        [actualHitProb, actualMissProb] = getCacheDecompositionResults(lambda_1, self.model.nodes{ind}, options);
                        self.model.nodes{ind}.setResultHitProb(actualHitProb);
                        self.model.nodes{ind}.setResultMissProb(actualMissProb);
                        
                        for r=1:length(hitClass)
                            if hitClass(r)>0
                                Pcs(r,hitClass(r)) = actualHitProb(r);
                            end
                        end
                        for r=1:length(missClass)
                            if missClass(r)>0
                                Pcs(r,missClass(r)) = actualMissProb(r);
                            end
                        end
                        for r=1:size(Pcs,1)
                            if sum(Pcs(r,:)) == 0
                                Pcs(r,r) = 1;
                            end
                        end
                        staticcache = ClassSwitch(staticmodel, 'StaticCache', Pcs);
                    otherwise
                        staticmodel.addNode(self.model.nodes{ind});
                end
            end
            
            for r=1:self.model.getNumberOfClasses
                staticmodel.addJobClass(self.model.classes{r});
            end
            
            staticmodel.linkFromNodeRoutingMatrix(Pnodes);
            
            % sanitize disabled classes
            for ind=1:self.model.getNumberOfNodes
                switch class(self.model.nodes{ind})
                    case 'Cache'
                        for r=1:length(staticcache.output.outputStrategy)
                            if isempty(staticcache.output.outputStrategy{r})
                                staticcache.output.outputStrategy{r} = {[],'Disabled'};
                            end
                        end
                        for r=(length(staticcache.output.outputStrategy)+1) : staticmodel.getNumberOfClasses
                            staticcache.output.outputStrategy{r} = {[],'Disabled'};
                        end
                end
            end
            %it
            
            solver = SolverMVA(staticmodel,options);
            AvgNodeTable = solver.getAvgNodeTable([],[],[],[],[],true);
            lambda_1  = lambda;
            lambda = tget(AvgNodeTable,staticcache).ArvR';
            %staticmodel_1 = staticmodel;
            if norm(lambda-lambda_1,1) < options.iter_tol
                sn = getStruct(staticmodel);
                break
            end
        end
    end
    self.model.refreshChains();
    switch method
        case {'aba.upper', 'aba.lower', 'bjb.upper', 'bjb.lower', 'pb.upper', 'pb.lower', 'gb.upper', 'gb.lower', 'sb.upper', 'sb.lower'}
            [QN,UN,RN,TN,CN,XN,lG,runtime] = solver_mva_bound_analyzer(sn, options);
            if nargout > 1
                analyzer = @(sn) solver_mva_bound_analyzer(sn, options);
            end
        otherwise
            if ~isempty(sn.lldscaling) || ~isempty(sn.cdscaling)
                [QN,UN,RN,TN,CN,XN,lG,runtime] = solver_mvald_analyzer(sn, options);
            else
                [QN,UN,RN,TN,CN,XN,lG,runtime] = solver_mva_analyzer(sn, options);
            end
            if nargout > 1
                analyzer = @(sn) solver_mva_analyzer(sn, options);
            end
    end
end
self.setAvgResults(QN,UN,RN,TN,CN,XN,runtime,method);
self.result.Prob.logNormConstAggr = lG;
end


function [hitProb,missProb] = getCacheDecompositionResults(lambda, cache, options)
isolationmodel = Network('isolatedCache');

n = cache.items.nitems; % number of items
m = cache.itemLevelCap; % cache capacity

isource = Source(isolationmodel, 'Source');
icache = Cache(isolationmodel, 'Cache', n, m, cache.replacementPolicy);
isink = Sink(isolationmodel, 'Sink');

R = length(lambda);
jobClass = cell(1,R);
hitClass = full(cache.getHitClass);
missClass = full(cache.getMissClass);
for r=1:length(lambda)
    jobClass{r} = OpenClass(isolationmodel, ['Class',num2str(r)], 0);
end
P = isolationmodel.initRoutingMatrix;
for r=1:length(lambda)
    if ~(lambda(r)>0.0001)
        isource.setArrival(jobClass{r}, Disabled());
        P{jobClass{r}, jobClass{r}}(isource, isink) =  1.0;
    else
        isource.setArrival(jobClass{r}, Exp(lambda(r)));
        icache.setRead(jobClass{r}, cache.popularity{r});
        icache.setHitClass(jobClass{r}, jobClass{hitClass(r)});
        icache.setMissClass(jobClass{r}, jobClass{missClass(r)});
        P{jobClass{r}, jobClass{r}}(isource, icache) =  1.0;
        P{jobClass{hitClass(r)}, jobClass{hitClass(r)}}(icache, isink) =  1.0;
        P{jobClass{missClass(r)}, jobClass{missClass(r)}}(icache, isink) =  1.0;
    end
end
isolationmodel.link(P);
SolverMVA(isolationmodel, options).getAvgNodeTable;
hitProb = full(icache.getResultHitProb);
missProb = full(icache.getResultMissProb);
end