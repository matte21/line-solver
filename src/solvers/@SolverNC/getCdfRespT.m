function RD = getCdfRespT(self, R)
% RD = GETCDFRESPT(R)

T0 = tic;
if nargin<2 %~exist('R','var')
    R = self.getAvgRespTHandles;
end
sn = self.getStruct;
[~,D,N,Z,~,S]= networkstruct_getpfparams(sn);
fcfsNodes = find(sn.schedid(sn.schedid ~= SchedStrategy.ID_INF) == SchedStrategy.ID_FCFS);
T = sum(N) * mean(1./sn.rates(fcfsNodes,:));
%tset = [0:T/100000:2.5*T/1000, T/1000:T/1000:T];
tset = logspace(-5,log10(T),100);
rates = sn.rates(sn.schedid == SchedStrategy.ID_FCFS,:);
RD = pfqn_stdf(D,N,Z,S,fcfsNodes,rates,tset);
%RD = pfqn_stdf_heur(D,N,Z,S,fcfsNodes,rates,tset);
runtime = toc(T0);
self.setDistribResults(RD, runtime);
end