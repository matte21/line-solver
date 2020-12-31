function Pn = getProbSys(self)
% PN = GETPROBSYSSTATE()

T0 = tic;
qn = self.getStruct;
% now compute marginal probability
[Pn,lG] = solver_nc_joint(qn, self.options);
self.result.('solver') = getName(self);
self.result.Prob.logNormConstAggr = lG;
self.result.Prob.joint = Pn;
runtime = toc(T0);
self.result.runtime = runtime;
end