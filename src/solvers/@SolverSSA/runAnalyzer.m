function [runtime, tranSysState, tranSync] = run(self, options)
% [RUNTIME, TRANSYSSTATE] = RUN()

T0=tic;
if nargin<2 %~exist('options','var')
    options = self.getOptions;
end

if self.enableChecks && ~self.supports(self.model)
    ME = MException('Line:FeatureNotSupportedBySolver', 'This model contains features not supported by the solver.');
    throw(ME);
end

Solver.resetRandomGeneratorSeed(options.seed);

sn = getStruct(self);

% TODO: add priors on initial state
sn.state = sn.state; % not used internally by SSA

[Q,U,R,T,C,X,~, tranSysState, tranSync, sn] = solver_ssa_analyzer(sn, options);
for isf=1:sn.nstateful
    ind = sn.statefulToNode(isf);
    switch sn.nodetype(sn.statefulToNode(isf))
        case NodeType.Cache
            self.model.nodes{sn.statefulToNode(isf)}.setResultHitProb(sn.varsparam{ind}.actualhitprob);
            self.model.nodes{sn.statefulToNode(isf)}.setResultMissProb(sn.varsparam{ind}.actualmissprob);
            self.model.refreshChains();
    end
end
runtime = toc(T0);
self.setAvgResults(Q,U,R,T,C,X,runtime);
self.result.space = sn.space;
end