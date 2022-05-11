function runtime = runAnalyzer(self, options)
% RUNTIME = RUN()
% Run the solver

T0=tic;
if nargin<2
    options = self.getOptions;
end

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

    for ind = 1:sn.nnodes
        if sn.nodetype(ind) == NodeType.Cache
            hitClass = self.model.nodes{ind}.getHitClass;
            missClass = self.model.nodes{ind}.getMissClass;
            hitprob = zeros(1,length(hitClass));
            for k=1:length(self.model.nodes{ind}.getHitClass)
                chain_k = sn.chains(:,k)>0;
                inchain = sn.chains(chain_k,:)>0;
                h = hitClass(k);
                m = missClass(k);
                if h>0 && m>0
                    hitprob(k) = XN(h) / nansum(XN(inchain)); %#ok<NANSUM>
                end
            end
            self.model.nodes{ind}.setResultHitProb(hitprob);
            self.model.nodes{ind}.setResultMissProb(1-hitprob);
        end
    end
    self.model.refreshChains();
else % queueing network
    if any(sn.nodetype == NodeType.Cache) % if integrated caching-queueing 
        [QN,UN,RN,TN,CN,XN,lG,hitprob,missprob,runtime] = solver_mva_cacheqn_analyzer(self, options);
        for ind = 1:sn.nnodes
            if sn.nodetype(ind) == NodeType.Cache
                self.model.nodes{ind}.setResultHitProb(hitprob(ind,:));
                self.model.nodes{ind}.setResultMissProb(missprob(ind,:));
            end
        end
        self.model.refreshChains();
    else % ordinary queueing network
        switch method
            case {'aba.upper', 'aba.lower', 'bjb.upper', 'bjb.lower', 'pb.upper', 'pb.lower', 'gb.upper', 'gb.lower', 'sb.upper', 'sb.lower'}
                [QN,UN,RN,TN,CN,XN,lG,runtime] = solver_mva_bound_analyzer(sn, options);
            otherwise
                if ~isempty(sn.lldscaling) || ~isempty(sn.cdscaling)
                    [QN,UN,RN,TN,CN,XN,lG,runtime] = solver_mvald_analyzer(sn, options);
                else
                    [QN,UN,RN,TN,CN,XN,lG,runtime] = solver_mva_analyzer(sn, options);
                end
        end
    end
end
self.setAvgResults(QN,UN,RN,TN,CN,XN,runtime,method);
self.result.Prob.logNormConstAggr = lG;
end
