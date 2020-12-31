function Pnir = getProbAggr(self, ist)
% PNIR = GETPROBSTATEAGGR(IST)

qn = self.getStruct;
if ~exist('ist','var')
    line_error(mfilename,'getProb requires to pass a parameter the station of interest.');
end
if ist > qn.nstations
    line_error(mfilename,'Station number exceeds the number of stations in the model.');
end
if ~isfield(self.options,'keep')
    self.options.keep = false;
end
T0 = tic;
qn.state = qn.state;

if isempty(self.result) || ~isfield(self.result,'Prob') || ~isfield(self.result.Prob,'marginal')
    Pnir = solver_ctmc_margaggr(qn, self.options);
    self.result.('solver') = getName(self);
    self.result.Prob.marginal = Pnir;
else
    Pnir = self.result.Prob.marginal;
end
runtime = toc(T0);
self.result.runtime = runtime;
Pnir = Pnir(ist);
end