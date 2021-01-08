function [runtime, analyzer] = runAnalyzer(self, options, config)
% RUNTIME = RUN()
% Run the solver

T0=tic;
if nargin<2
    options = self.getOptions;
end
if nargin<3
    config = [];
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

sn = getStruct(self);

if (strcmp(options.method,'exact')||strcmp(options.method,'mva')) && ~self.model.hasProductFormSolution
    line_error(mfilename,'The exact method requires the model to have a product-form solution. This model does not have one. You can use Network.hasProductFormSolution() to check before running the solver.');
end

method = options.method;

if sn.nclasses==1 && sn.nclosedjobs == 0 && length(sn.nodetype)==3 && all(sort(sn.nodetype)' == sort([NodeType.Source,NodeType.Queue,NodeType.Sink])) % is a queueing system
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
        line_error(mfilename,'Caching analysis not supported yet by MVA in general networks.');
    end
    switch method
        case {'aba.upper', 'aba.lower', 'bjb.upper', 'bjb.lower', 'pb.upper', 'pb.lower', 'gb.upper', 'gb.lower'}
            [QN,UN,RN,TN,CN,XN,lG,runtime] = solver_mva_bound_analyzer(sn, options);
            if nargout > 1
                analyzer = @(sn) solver_mva_bound_analyzer(sn, options);
            end
        otherwise
            [QN,UN,RN,TN,CN,XN,lG,runtime] = solver_mva_analyzer(sn, options);
            if nargout > 1
                analyzer = @(sn) solver_mva_analyzer(sn, options);
            end
    end
end
self.setAvgResults(QN,UN,RN,TN,CN,XN,runtime,method);
self.result.Prob.logNormConstAggr = lG;
end
