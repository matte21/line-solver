function RD = getCdfRespT(self, R)
% RD = GETCDFRESPT(R)

T0 = tic;
if nargin<2 %~exist('R','var')
    R = self.getAvgRespTHandles;
end
qn = self.getStruct;
self.getAvg; % get steady-state solution
options = self.getOptions;
options.init_sol = self.result.solverSpecific.odeStateVec;
RD = solver_fluid_passage_time(qn, options);
runtime = toc(T0);
self.setDistribResults(RD, runtime);
end