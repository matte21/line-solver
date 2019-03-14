function [simDoc, section] = saveLogTunnel(self, simDoc, section, currentNode)
% Copyright (c) 2012-2019, Imperial College London
% All rights reserved.
loggerNodesCP = {'java.lang.String','java.lang.String'};
for i=3:9 loggerNodesCP{i} = 'java.lang.Boolean'; end
loggerNodesCP{10} = 'java.lang.Integer';

loggerNodesNames = {'logfileName','logfilePath','logExecTimestamp', ...
    'logLoggerName','logTimeStamp','logJobID', ...
    'logJobClass','logTimeSameClass','logTimeAnyClass', ...
    'numClasses'};
numOfClasses = length(self.model.classes);

% logger specific path does not work in JMT at the moment
if ~strcmpi(currentNode.filePath(end),filesep)
    currentNode.filePath = [currentNode.filePath, filesep];
end

loggerNodesValues = {currentNode.fileName, currentNode.filePath, ...
    currentNode.wantExecTimestamp,currentNode.wantLoggerName, ...
    currentNode.wantTimeStamp,currentNode.wantJobID, ...
    currentNode.wantJobClass,currentNode.wantTimeSameClass, ...
    currentNode.wantTimeAnyClass,int2str(numOfClasses)};

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
