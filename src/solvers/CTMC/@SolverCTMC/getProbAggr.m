function Pnir = getProbAggr(self, ist)
% PNIR = GETPROBSTATEAGGR(IST)

if GlobalConstants.DummyMode
    Pnir = NaN;
    return
end

if ~isnumeric(ist) % station object
    ist = ist.index; 
end

sn = self.getStruct;
if nargin<2 %~exist('ist','var')
    line_error(mfilename,'getProb requires to pass a parameter the station of interest.');
end
if ist > sn.nstations
    line_error(mfilename,'Station number exceeds the number of stations in the model.');
end
if ~isfield(self.options,'keep')
    self.options.keep = false;
end
T0 = tic;
sn.state = sn.state;

if isempty(self.result) || ~isfield(self.result,'Prob') || ~isfield(self.result.Prob,'marginal')
    Pnir = solver_ctmc_margaggr(sn, self.options);
    self.result.('solver') = getName(self);
    self.result.Prob.marginal = Pnir;
else
    Pnir = self.result.Prob.marginal;
end
runtime = toc(T0);
self.result.runtime = runtime;
Pnir = Pnir(ist);
end