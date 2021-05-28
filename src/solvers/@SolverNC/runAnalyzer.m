function runtime = runAnalyzer(self, options, config)
% RUNTIME = RUN()
% Run the solver

sn = getStruct(self); % doesn't need initial state

T0=tic;
if nargin<2
    options = self.getOptions;
end
if nargin<3
    config = [];
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
            self.model.nodes{sn.statefulToNode(isf)}.setResultHitProb(prob);
            self.model.nodes{sn.statefulToNode(isf)}.setResultMissProb(1-prob);
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
            self.model.nodes{sn.statefulToNode(isf)}.setResultHitProb(hitprob);
            self.model.nodes{sn.statefulToNode(isf)}.setResultMissProb(1-hitprob);
        end
    end
    self.model.refreshChains;
else % queueing network
    if any(sn.nodetype == NodeType.Cache)
        line_error(mfilename,'Caching analysis not supported yet by NC in general networks.');
    end
    configLDSolver = false;
    if isfield(options,'config')
        for c=1:2:length(options.config)
            switch options.config{c}
                case 'ld'
                    configLDSolver = options.config{c+1};
            end
        end
    end
    if configLDSolver
        [QN,UN,RN,TN,CN,XN,lG,runtime] = solver_ncld_analyzer(sn, options);
    else
        [QN,UN,RN,TN,CN,XN,lG,runtime] = solver_nc_analyzer(sn, options);
        %[QN,UN,RN,TN,CN,XN,lG,runtime] = solver_ncld_analyzer(sn, options)
    end
    
end
self.setAvgResults(QN,UN,RN,TN,CN,XN,runtime);
self.result.Prob.logNormConstAggr = lG;
end