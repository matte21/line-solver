function runtime = runAnalyzer(self, options)
% RUNTIME = RUN()
% Run the solver

T0=tic;
iter = NaN;
if nargin<2
    options = self.getOptions;
end
sn = getStruct(self); % this gets modified later on so pass by copy

hasOpenClasses = any(sn.nodetype==NodeType.ID_SOURCE);
switch options.method
    case {'java','jline.fluid','jline.fluid.matrix','jline.fluid.closing'}
        jmodel = LINE2JLINE(self.model);
        M = jmodel.getNumberOfStatefulNodes;
        R = jmodel.getNumberOfClasses;
        switch options.method
            case 'jline.fluid.closing'
                jsolver = JLINE.SolverFluid(jmodel,'closing');
            case 'jline.fluid.matrix'
                jsolver = JLINE.SolverFluid(jmodel,'matrix');
            otherwise
                jsolver = JLINE.SolverFluid(jmodel);
        end
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
        self.setAvgResults(QN,UN,RN,TN,AN,[],CN,XN,runtime,'jline.fluid',lastiter);
        self.result.Prob.logNormConstAggr = lG;
        return
    case {'matrix'}
        if hasOpenClasses
            line_error(mfilename,'The matrix solver does not support open arrivals. Use options.method=''closing'' instead.');
            options.method = 'closing';
        end
    case {'default'}
        if hasOpenClasses
            options.method = 'closing';
        else
            options.method = 'matrix';
        end
    case {'closing','statedep','softmin'}
        % do nothing
    otherwise
        line_warning(mfilename,'This solver does not support the specified method. Setting to default.');
        options.method  = 'default';
end

if isinf(options.timespan(1))
    if options.verbose  == 2
        line_warning(mfilename,'%s requires options.timespan(1) to be finite. Setting it to 0.',mfilename);
    end
    options.timespan(1) = 0;
end

if options.timespan(1) == options.timespan(2)
    line_warning(mfilename,'%s: timespan is a single point, unsupported. Setting options.timespace(1) to 0.\n',mfilename);
    options.timespan(1) = 0;
end

if self.enableChecks && ~self.supports(self.model)
    line_error(mfilename,'This model contains features not supported by the solver.');
end

self.setOptions(options);

M = sn.nstations;
K = sn.nclasses;

%%
lastSol= [];
Q = zeros(M,K); R = zeros(M,K); T = zeros(M,K);
U = zeros(M,K); C = zeros(1,K); X = zeros(1,K);
Qt=[];
s0 = sn.state;
s0prior = sn.stateprior;
s0_sz = cellfun(@(x) size(x,1), s0)';
s0_id = pprod(s0_sz-1);
while s0_id>=0 % for all possible initial states
    s0prior_val = 1;
    for ind=1:sn.nnodes
        if sn.isstateful(ind)
            isf = sn.nodeToStateful(ind);
            s0prior_val = s0prior_val * s0prior{isf}(1+s0_id(isf)); % update prior
            %sn.state{isf} = s0{isf}(1+s0_id(isf),:); % assign initial state to network
            self.model.nodes{ind}.setState(s0{isf}(1+s0_id(isf),:));
        end
    end
    sn = self.model.getStruct;
    if s0prior_val > 0
        %useJLine = false;
        %if useJLine
        %    [Qfull, Ufull, Rfull, Tfull, Cfull, Xfull, t, Qfull_t, Ufull_t, Tfull_t, lastSol] = solver_fluid_analyzer_jline(self.model, options);
        %else
        [Qfull, Ufull, Rfull, Tfull, Cfull, Xfull, t, Qfull_t, Ufull_t, Tfull_t, lastSol, iter] = solver_fluid_analyzer(sn, options);
        %end

        [t,uniqueIdx] = unique(t);
        if isempty(lastSol) % if solution fails
            Q = NaN*ones(M,K); R = NaN*ones(M,K);
            T = NaN*ones(M,K); U = NaN*ones(M,K);
            C = NaN*ones(1,K); X = NaN*ones(1,K);
            Qt = cell(M,K); Ut = cell(M,K); Tt = cell(M,K);
            for ist=1:M
                for r=1:K
                    Qt{ist,r} = [NaN,NaN];
                    Ut{ist,r} = [NaN,NaN];
                    Tt{ist,r} = [NaN,NaN];
                end
            end
        else
            if isempty(self.result) && max(size(Qt))==0 %~exist('Qt','var')
                Q = Qfull*s0prior_val;
                R = Rfull*s0prior_val;
                T = Tfull*s0prior_val;
                U = Ufull*s0prior_val;
                C = Cfull*s0prior_val;
                X = Xfull*s0prior_val;
                Qt = cell(M,K);
                Ut = cell(M,K);
                Tt = cell(M,K);
                for ist=1:M
                    for r=1:K
                        Qfull_t{ist,r} = Qfull_t{ist,r}(uniqueIdx);
                        Ufull_t{ist,r} = Ufull_t{ist,r}(uniqueIdx);
                        Tfull_t{ist,r} = Tfull_t{ist,r}(uniqueIdx);
                        Qt{ist,r} = [Qfull_t{ist,r} * s0prior_val,t];
                        Ut{ist,r} = [Ufull_t{ist,r} * s0prior_val,t];
                        Tt{ist,r} = [Tfull_t{ist,r} * s0prior_val,t];
                    end
                end
            else
                Q = Q + Qfull*s0prior_val;
                R = R + Rfull*s0prior_val;
                T = T + Tfull*s0prior_val;
                U = U + Ufull*s0prior_val;
                C = C + Cfull*s0prior_val;
                X = X + Xfull*s0prior_val;
                for ist=1:M
                    for r=1:K
                        [t,uniqueIdx] = unique(t);
                        Qfull_t{ist,r} = Qfull_t{ist,r}(uniqueIdx);
                        Ufull_t{ist,r} = Ufull_t{ist,r}(uniqueIdx);
                        %                                  Tfull_t{i,r} = Tfull_t{i,r}(uniqueIdx);

                        tunion = union(Qt{ist,r}(:,2), t);
                        dataOld = interp1(Qt{ist,r}(:,2),Qt{ist,r}(:,1),tunion);
                        dataNew = interp1(t,Qfull_t{ist,r},tunion);
                        Qt{ist,r} = [dataOld + s0prior_val * dataNew, tunion];

                        dataOld = interp1(Ut{ist,r}(:,2),Ut{ist,r}(:,1),tunion);
                        dataNew = interp1(t,Ufull_t{ist,r},tunion);
                        Ut{ist,r} = [dataOld + s0prior_val * dataNew, tunion];

                        %                                 dataOld = interp1(Tt{i,r}(:,2),Tt{i,r}(:,1),tunion);
                        %                                 dataNew = interp1(t,Tfull_t{i,r},tunion);
                        %                                 Tt{i,r} = [dataOld + s0prior_val * dataNew, tunion];
                    end
                end
            end
        end
    end
    s0_id=pprod(s0_id,s0_sz-1); % update initial state
end
runtime = toc(T0);
self.result.solverSpecific = lastSol;
QN = Q; UN=U; RN=R; TN=T; CN=C; XN=X;
M = sn.nstations;
R = sn.nclasses;
if ~isempty(getAvgTputHandles(self))
    AN = zeros(M,R);
    for i=1:M
        for j=1:M
            for k=1:R
                for r=1:R
                    AN(i,k) = AN(i,k) + T(j,r)*sn.rt((j-1)*R+r, (i-1)*R+k);
                end
            end
        end
    end
end
% Compute average arrival rate at steady-state
self.setAvgResults(QN,UN,RN,TN,AN,[],CN,XN,runtime,options.method,iter);
Rt={}; Xt={}; Ct={};
self.setTranAvgResults(Qt,Ut,Rt,Tt,Ct,Xt,runtime);
end