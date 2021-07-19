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

sn = getStruct(self); % doesn't need initial state

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
    %     if any(sn.nodetype == NodeType.Cache)
    %         %% This case works only in a special case for now
    %
    %         %line_error(mfilename,'Caching analysis not supported yet by MVA in general networks.');
    %         cacheindex = sn.varsparam(find(sn.nodetype == NodeType.Cache));
    %         initclassindex = find(cell2mat(cellfun(@(x) sum(isnan(x)),cacheindex{:}.pref,'uniformoutput',false))==0);
    %         u = size(initclassindex,2);  % stream (== itementries?)
    %         n = cacheindex{:}.nitems; % total items
    %         m = cacheindex{:}.cap;  % capacity
    %         h = 2;  % lists
    %
    %         kset=1:n;
    %         R={};
    %         r=ones(u,n,h);
    %         for k=1:n
    %             for v=1:u
    %                 R{v,k}=zeros(h);
    %                 for l=2:(h+1)
    %                     R{v,k}(l-1,l)=r(v,k,l-1);
    %                     R{v,k}(l-1,l-1)=1-r(v,k,l-1);
    %                     R{v,k}(h+1,h+1)=1;
    %                 end
    %             end
    %          end
    %
    %         %% iterative ray
    %          lambda = [];
    %          X = ones(2,u);
    %          X_1 = X*1e3;
    %          goon = true;
    %          while goon
    %              for v=1:u
    %                  Pmf{v} = cell2mat(cacheindex{:}.pref(initclassindex));
    %                  Xtot(v) = sum(X(:,v));
    %                      for k=kset
    %                          for j=1:(h+1)
    %                              lambda(v,k,j) = Pmf{v}(1,k)*Xtot(v);
    %                          end
    %                      end
    %              end
    %           [gamma,u,~,h] = mucache_gamma(lambda,R);
    %           [~,MU] = mucache_miss_rayint(gamma,m,lambda);
    %                                 %%
    %           pHit = 1-MU./Xtot'
    %           subnetwork = mucache_generate_subnetwork(self.model,pHit);
    %           sn = subnetwork.getStruct();
    %           AvgTableNet = SolverMVA(subnetwork).getAvgTable;
    %           X(1,1) = AvgTableNet.Tput(4);
    %           X(2,1) = AvgTableNet.Tput(5)+AvgTableNet.Tput(6);
    %
    %           if max(abs(1-X./X_1))<1e-3
    %               goon=false;
    %           end
    %           X_1 = X;
    %          end
    %        Xray=X;
    %     end
    
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
