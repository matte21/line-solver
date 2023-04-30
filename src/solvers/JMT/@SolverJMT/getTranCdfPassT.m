function RD = getTranCdfPassT(self, R)
% RD = GETTRANCDFPASST(R)

if GlobalConstants.DummyMode
    RD = NaN;
    return
end

if nargin<2 %~exist('R','var')
    R = getAvgRespTHandles(self);
end
sn = self.getStruct;
RD = cell(sn.nstations, sn.nclasses);
cdfmodel = self.model.copy;
cdfmodel.resetNetwork;
isNodeClassLogged = false(cdfmodel.getNumberOfNodes, cdfmodel.getNumberOfClasses);
for i= 1:cdfmodel.getNumberOfStations
    for r=1:cdfmodel.getNumberOfClasses
        if ~R{i,r}.disabled
            ni = self.model.getNodeIndex(cdfmodel.getStationNames{i});
            isNodeClassLogged(ni,r) = true;
        end
    end
end
Plinked = sn.rtorig;
isNodeLogged = max(isNodeClassLogged,[],2);
logpath = lineTempDir;
cdfmodel.linkAndLog(Plinked, isNodeLogged, logpath);
SolverJMT(cdfmodel, self.getOptions).getAvg(); % log data
logData = SolverJMT.parseLogs(cdfmodel, isNodeLogged, MetricType.RespT);
% from here convert from nodes in logData to stations
for i= 1:cdfmodel.getNumberOfStations
    ni = cdfmodel.getNodeIndex(cdfmodel.getStationNames{i});
    for r=1:cdfmodel.getNumberOfClasses
        if isNodeClassLogged(ni,r)
            if ~isempty(logData{ni,r})
                [F,X] = ecdf(logData{ni,r}.RespT);
                RD{i,r} = [F,X];
            end
        end
    end
end
end