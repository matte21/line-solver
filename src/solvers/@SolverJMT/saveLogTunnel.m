function [simDoc, section] = saveLogTunnel(self, simDoc, section, ind)
% [SIMDOC, SECTION] = SAVELOGTUNNEL(SIMDOC, SECTION, NODEIDX)

% Copyright (c) 2012-2021, Imperial College London
% All rights reserved.

qn = self.getStruct;
loggerNodesCP = {'java.lang.String','java.lang.String'};
for i=3:9 loggerNodesCP{i} = 'java.lang.Boolean'; end
loggerNodesCP{10} = 'java.lang.Integer';

loggerNodesNames = {'logfileName','logfilePath','logExecTimestamp', ...
    'logLoggerName','logTimeStamp','logJobID', ...
    'logJobClass','logTimeSameClass','logTimeAnyClass', ...
    'numClasses'};
numOfClasses = qn.nclasses;

% logger specific path does not work in JMT at the moment
if ~strcmpi(qn.varsparam{ind}.filePath(end),filesep)
    currentNode.filePath = [qn.varsparam{ind}.filePath, filesep];
end

loggerNodesValues = {qn.varsparam{ind}.fileName, qn.varsparam{ind}.filePath, ...
    qn.varsparam{ind}.startTime,qn.varsparam{ind}.loggerName, ...
    qn.varsparam{ind}.timestamp,qn.varsparam{ind}.jobID, ...
    qn.varsparam{ind}.jobClass,qn.varsparam{ind}.timeSameClass, ...
    qn.varsparam{ind}.timeAnyClass,int2str(numOfClasses)};

for j=1:length(loggerNodesValues)
    loggerNode = simDoc.createElement('parameter');
    loggerNode.setAttribute('classPath', loggerNodesCP{j});
    loggerNode.setAttribute('name', loggerNodesNames{j});
    valueNode = simDoc.createElement('value');
    valueNode.appendChild(simDoc.createTextNode(loggerNodesValues{j}));
    loggerNode.appendChild(valueNode);
    section.appendChild(loggerNode);
end
end
