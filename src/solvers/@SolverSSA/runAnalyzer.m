function [runtime, tranSysState, tranSync] = run(self, options)
% [RUNTIME, TRANSYSSTATE] = RUN()

T0=tic;
if ~exist('options','var')
    options = self.getOptions;
end

if self.enableChecks && ~self.supports(self.model)
    ME = MException('Line:FeatureNotSupportedBySolver', 'This model contains features not supported by the solver.');
    throw(ME);
end

Solver.resetRandomGeneratorSeed(options.seed);

qn = getStruct(self);

% TODO: add priors on initial state
qn.state = qn.state; % not used internally by SSA

[Q,U,R,T,C,X,~, tranSysState, tranSync, qn] = solver_ssa_analyzer(qn, options);
for isf=1:qn.nstateful
    ind = qn.statefulToNode(isf);
    switch qn.nodetype(qn.statefulToNode(isf))
        case NodeType.Cache
            self.model.nodes{qn.statefulToNode(isf)}.setResultHitProb(qn.varsparam{ind}.actualhitprob);
            self.model.nodes{qn.statefulToNode(isf)}.setResultMissProb(qn.varsparam{ind}.actualmissprob);
            self.model.refreshChains();
    end
end
runtime = toc(T0);
self.setAvgResults(Q,U,R,T,C,X,runtime);
self.result.space = qn.space;
end