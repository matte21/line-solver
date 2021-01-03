function Pnir = getProbAggr(self, node, state_a)
% PNIR = GETPROBAGGR(NODE, STATE_A)

T0 = tic;
qn = self.getStruct;
if nargin<3 %~exist('state_a','var')
    state_a = qn.state{qn.nodeToStateful(node.index)};
end
% now compute marginal probability
ist = qn.nodeToStation(node.index);
qn.state{ist} = state_a;

self.result.('solver') = getName(self);
if isfield(self.result,'Prob') && isfield(self.result.Prob,'logNormConstAggr') && isfinite(self.result.Prob.logNormConstAggr)
    [Pnir,lG] = solver_nc_margaggr(qn, self.options, self.result.Prob.logNormConstAggr);
else
    [Pnir,lG] = solver_nc_margaggr(qn, self.options);
    self.result.Prob.logNormConstAggr = lG;
end
self.result.Prob.marginal = Pnir;
runtime = toc(T0);
self.result.runtime = runtime;
Pnir = Pnir(ist);
end