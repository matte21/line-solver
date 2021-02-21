function RD = getCdfRespT(self, R, config)
% RD = GETCDFRESPT(R)
T0 = tic;
if nargin<2 %~exist('R','var')
    R = self.getAvgRespTHandles;
end
if nargin<3 %~exist('config','var')
    config = self.getOptions.config;
    config.algorithm = 'rd';
end
RD = {};
sn = self.getStruct;
[~,D,N,Z,~,S]= snGetProductFormParams(sn);
fcfsNodes = find(sn.schedid(sn.schedid ~= SchedStrategy.ID_INF) == SchedStrategy.ID_FCFS);
if ~isempty(fcfsNodes)
    T = max(sum(N) * mean(1./sn.rates(fcfsNodes,:)));
    tset = logspace(-5,log10(T),100);
    rates = sn.rates(sn.schedid == SchedStrategy.ID_FCFS,:);
    switch config.algorithm
        case 'exact'
        RD = pfqn_stdf(D,N,Z,S,fcfsNodes,rates,tset);
        case 'rd'
        RD = pfqn_stdf_heur(D,N,Z,S,fcfsNodes,rates,tset);
    end
    for i=1:size(RD,1)
        for j=1:size(RD,2)
            RD{i,j}=real(RD{i,j});
        end
    end
    runtime = toc(T0);
    self.setDistribResults(RD, runtime);
else
    line_warning(mfilename, 'getCdfRespT applies only to FCFS nodes.');    
    return
end
end