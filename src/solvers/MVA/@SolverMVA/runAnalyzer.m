function runtime = runAnalyzer(self, options)
% RUNTIME = RUN()
% Run the solver

%global GlobalConstants.FineTol GlobalConstants.Immediate

T0=tic;
iter = 0;
if nargin<2
    options = self.getOptions;
end

if self.enableChecks && ~self.supports(self.model)
    line_error(mfilename,'This model contains features not supported by the solver.');
end

Solver.resetRandomGeneratorSeed(options.seed);

switch options.method
%     case 'fast'
%          if snHasProductForm(sn) 
%             Tstart = tic;
%             [Q,U,R,T,C,X,lG,iter] = solver_amva(sn, options);
%             runtime = toc(Tstart);             
%             self.setAvgResults(QN,UN,RN,TN,AN,[],CN,XN,runtime,method,iter);
%             self.result.Prob.logNormConstAggr = lG;
%          end
    case {'java','jline.amva'}
        jmodel = LINE2JLINE(self.model);
        M = jmodel.getNumberOfStatefulNodes;
        R = jmodel.getNumberOfClasses;
        jsolver = JLINE.SolverMVA(jmodel);
        [QN,UN,RN,~,TN] = JLINE.arrayListToResults(jsolver.getAvgTable);
        runtime = toc(T0);
        CN = [];
        XN = [];
        QN = reshape(QN',R,M)';
        UN = reshape(UN',R,M)';
        RN = reshape(RN',R,M)';
        TN = reshape(TN',R,M)';
        lG = NaN;
        lastiter = NaN;
        sn = self.getStruct;
        M = sn.nstations;
        R = sn.nclasses;
        T = getAvgTputHandles(self);
        if ~isempty(T) && ~isempty(TN)
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
        else
            AN = [];
        end
        self.setAvgResults(QN,UN,RN,TN,AN,[],CN,XN,runtime,'jline.amva',lastiter);
        self.result.Prob.logNormConstAggr = lG;
        return
    otherwise
        sn = getStruct(self); % doesn't need initial state
        snorig = sn;
        forkLoop = true;
        forkIter = 0;
        % create artificial classes arrival rates
        forkLambda = GlobalConstants.FineTol * ones(1, 2*sn.nclasses*sum(sn.nodetype==NodeType.ID_FORK));
        QN = GlobalConstants.Immediate * ones(1, sn.nclasses);
        QN_1 = 0*QN;
        UN = 0*QN;
        forceOneMoreIteration = false;
        while (forkLoop && forkIter < options.iter_max)
            if self.model.hasFork
                forkIter = forkIter + 1;
                if forkIter == 1
                    [nonfjmodel, fjclassmap, fjforkmap, fanout] = self.model.approxForkJoins(forkLambda);
                else
                    %line_printf('Fork-join iteration %d\n',forkIter);
                    for r=1:length(fjclassmap) % r is the auxiliary class
                        s = fjclassmap(r);
                        if s>0
                            nonfjSource = nonfjmodel.getSource;
                            if fanout(s)>0
                                if ~nonfjSource.arrivalProcess{r}.isDisabled
                                    nonfjSource.arrivalProcess{r}.updateRate((fanout(s)-1)*forkLambda(r));
                                end
                            end
                        end
                        nonfjmodel.refreshStruct();
                    end
                end
                sn = nonfjmodel.getStruct(false);
                if max(abs(1-QN_1./ QN)) < 0.005 & forkIter > 2
                    forkLoop = false;
                else
                    if self.model.hasOpenClasses
                        sourceIndex = self.model.getSource.index;
                        UNnosource = UN; UNnosource(sourceIndex,:) = 0;
                        if max(sum(UNnosource,2))>0.99 & self.model.hasOpenClasses
                            line_warning(mfilename,'The model may be unstable: the utilization of station %i exceeds 99 percent.',maxpos(sum(UNnosource,2)));
                        end
                    end
                    %[QN_1;QN]
                    QN_1 = QN;
                end
            else
                forkLoop = false;
            end
            if strcmp(options.method,'exact')  && ~self.model.hasProductFormSolution
                line_error(mfilename,'The exact method requires the model to have a product-form solution. This model does not have one.\nYou can use Network.hasProductFormSolution() to check before running the solver.\n Run the ''mva'' method to obtain an approximation based on the exact MVA algorithm.');
            end
            if strcmp(options.method,'mva') && ~self.model.hasProductFormSolution
                line_warning(mfilename,'The exact method requires the model to have a product-form solution. This model does not have one.\nYou can use Network.hasProductFormSolution() to check before running the solver.\nSolverMVA will return an approximation generated by an exact MVA algorithm.');
            end

            method = options.method;

            if sn.nclasses==1 && sn.nclosedjobs == 0 && length(sn.nodetype)==3 && all(sort(sn.nodetype)' == sort([NodeType.Source,NodeType.Queue,NodeType.Sink])) % is an open queueing system
                [QN,UN,RN,TN,CN,XN,lG,runtime,lastiter] = solver_mva_qsys_analyzer(sn, options);
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
                [QN,UN,RN,TN,CN,XN,lG,runtime,lastiter] = solver_mva_cache_analyzer(sn, options);

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
                %self.model.refreshChains();
                self.model.refreshStruct(true);
            else % queueing network
                if any(sn.nodetype == NodeType.Cache) % if integrated caching-queueing
                    [QN,UN,RN,TN,CN,XN,lG,hitprob,missprob,runtime,lastiter] = solver_mva_cacheqn_analyzer(self, options);
                    for ind = 1:sn.nnodes
                        if sn.nodetype(ind) == NodeType.Cache
                            self.model.nodes{ind}.setResultHitProb(hitprob(ind,:));
                            self.model.nodes{ind}.setResultMissProb(missprob(ind,:));
                        end
                    end
                    %self.model.refreshChains();
                    self.model.refreshStruct(true);
                else % ordinary queueing network
                    switch method
                        case {'aba.upper', 'aba.lower', 'bjb.upper', 'bjb.lower', 'pb.upper', 'pb.lower', 'gb.upper', 'gb.lower', 'sb.upper', 'sb.lower'}
                            [QN,UN,RN,TN,CN,XN,lG,runtime,lastiter] = solver_mva_bound_analyzer(sn, options);
                        otherwise
                            if ~isempty(sn.lldscaling) || ~isempty(sn.cdscaling)
                                [QN,UN,RN,TN,CN,XN,lG,runtime,lastiter] = solver_mvald_analyzer(sn, options);
                            else
                                [QN,UN,RN,TN,CN,XN,lG,runtime,lastiter] = solver_mva_analyzer(sn, options);
                            end
                    end
                end
            end
            if self.model.hasFork
                sn = self.getStruct;
                for f=find(sn.nodetype == NodeType.ID_FORK)'
                    TNfork = zeros(1,sn.nclasses);
                    for c=1:sn.nchains
                        inchain = find(sn.chains(c,:));
                        for r=inchain(:)'
                            TNfork(r) =  (sn.nodevisits{c}(f,r) / sum(sn.visits{c}(sn.stationToStateful(sn.refstat(r)),inchain))) * sum(TN(sn.refstat(r),inchain));
                        end
                    end
                    forkauxclasses = find(fjforkmap==f);
                    % for all forks, find the associated join
                    for s=forkauxclasses(:)'
                        r = fjclassmap(s); % original class associated to auxiliary class s
                        forkLambda(s) = mean([forkLambda(s); TNfork(r)],1);
                    end
                end
                % merge back artificial classes into their original classes
                for r=1:length(fjclassmap)
                    s = fjclassmap(r);
                    if s>0
                        QN(:,s) = QN(:,s) + QN(:,r);
                        UN(:,s) = UN(:,s) + UN(:,r);
                        %TN(:,s) = TN(:,s) + TN(:,r);
                        %RN(:,s) = RN(:,s) + RN(:,r);
                        for i=find(snorig.nodetype == NodeType.ID_DELAY | snorig.nodetype == NodeType.ID_QUEUE)'
                            TN(snorig.nodeToStation(i),s) = TN(snorig.nodeToStation(i),s) + TN(snorig.nodeToStation(i),r);
                        end
                        RN(:,s) = QN(:,s) ./ TN(:,s);
                        %CN(:,s) = CN(:,s) + CN(:,r);
                        %XN(:,s) = XN(:,s) + XN(:,r);
                    end
                end
                QN(:,fjclassmap>0) = [];
                UN(:,fjclassmap>0) = [];
                RN(:,fjclassmap>0) = [];
                TN(:,fjclassmap>0) = [];
                CN(:,fjclassmap>0) = [];
                XN(:,fjclassmap>0) = [];
            end
            iter = iter + lastiter;
        end

        sn = self.model.getStruct();

        % Compute average arrival rate at steady-state
        M = sn.nstations;
        R = sn.nclasses;
        T = getAvgTputHandles(self);
        if ~isempty(T) && ~isempty(TN)
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
        else
            AN = [];
        end
        self.setAvgResults(QN,UN,RN,TN,AN,[],CN,XN,runtime,method,iter);
        self.result.Prob.logNormConstAggr = lG;
end
%if iter>1000
%    keyboard
%end
end


