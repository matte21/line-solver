function runtime = runAnalyzer(self, options)
% RUNTIME = RUN()
% Run the solver

sn = getStruct(self); % doesn't need initial state

T0=tic;
iter = NaN;
if nargin<2
    options = self.getOptions;
end

if strcmp(options.method,'exact') && ~self.model.hasProductFormSolution
    line_error(mfilename,'The exact method requires the model to have a product-form solution. This model does not have one. You can use Network.hasProductFormSolution() to check before running the solver.');
end

if self.enableChecks && ~self.supports(self.model)
    ME = MException('Line:FeatureNotSupportedBySolver', 'This model contains features not supported by the solver.');
    throw(ME);
end

Solver.resetRandomGeneratorSeed(options.seed);

if sn.nclosedjobs == 0 && length(sn.nodetype)==3 && all(sort(sn.nodetype)' == sort([NodeType.Source,NodeType.Cache,NodeType.Sink])) % is a non-rentrant cache
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
    [QN,UN,RN,TN,CN,XN,lG,pij,runtime] = solver_nc_cache_analyzer(sn, options);
    self.result.Prob.itemProb = pij;
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
    if any(sn.nodetype == NodeType.Cache) % if integrated caching-queueing
        [QN,UN,RN,TN,CN,XN,lG,hitprob,missprob,runtime,iter] = solver_nc_cacheqn_analyzer(self, options);
        for ind = 1:sn.nnodes
            if sn.nodetype(ind) == NodeType.Cache
                self.model.nodes{ind}.setResultHitProb(hitprob(ind,:));
                self.model.nodes{ind}.setResultMissProb(missprob(ind,:));
            end
        end
        self.model.refreshChains();
    else % ordinary queueing network
        if ~isempty(sn.lldscaling) || ~isempty(sn.cdscaling)
            [QN,UN,RN,TN,CN,XN,lG,runtime,iter] = solver_ncld_analyzer(sn, options);
        else
            [QN,UN,RN,TN,CN,XN,lG,runtime,iter] = solver_nc_analyzer(sn, options);
        end
    end
end
% Compute average arrival rate at steady-state
M = sn.nstations;
R = sn.nclasses;
T = getAvgTputHandles(self);
if ~isempty(T)
    AN = zeros(M,R);
    for i=1:M
        for j=1:M
            for k=1:R
                for r=1:R
                    AN(i,k) = AN(i,k) + TN(j,r)*sn.rt((j-1)*R+r, (i-1)*R+k);
                end
            end
        end
    end
end
self.setAvgResults(QN,UN,RN,TN,AN,[],CN,XN,runtime,options.method,iter);
self.result.Prob.logNormConstAggr = real(lG);
end