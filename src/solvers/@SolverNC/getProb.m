function Pnir = getProb(self, node, state)
% PNIR = GETPROB(NODE, STATE)
if nargin<3 %~exist('state','var')
    state = qn.state{qn.nodeToStateful(node.index)};
end
T0 = tic;
qn = self.getStruct;
% now compute marginal probability
if isa(node,'Node')
    ist = qn.nodeToStation(node.index);
else
    ist = node;    
end
qn.state{ist} = state;
if isfield(self.result.Prob,'logNormConstAggr') && isfinite(self.result.Prob.logNormConstAggr)
    [Pnir,lG] = solver_nc_marg(qn, self.options, self.result.Prob.logNormConstAggr);
else
    [Pnir,lG] = solver_nc_marg(qn, self.options);
    self.result.Prob.logNormConstAggr = lG;
end
self.result.('solver') = getName(self);
self.result.Prob.marginal = Pnir;
runtime = toc(T0);
self.result.runtime = runtime;
Pnir = Pnir(ist);
end