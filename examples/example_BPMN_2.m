% EXAMPLE_BPMN_2 exemplifies the use of LINE to analize BPMN models.
%
% Copyright (c) 2012-2016, Imperial College London
% All rights reserved.

clear;
clc;

%% input files: bpmn + extensions
filename = fullfile(pwd,'data','BPMN','bpmn_messages_tasks.bpmn');
extFilename = fullfile(pwd,'data','BPMN','bpmn_ext_messages_tasks.xml');

verbose = 1;
%% input files parsing
model = BPMN.parseXML_BPMN(filename, verbose);
modelExt = BPMN.parseXML_BPMNextensions(extFilename, verbose);
%% create lqn model from bpmn
myLQN = BPMN2LQN(model, modelExt);

%% obtain line performance model from lqn
options = SolverLQNS.defaultOptions;
options.keep = true; % uncomment to keep the intermediate XML files generates while translating the model to LQNS

solver{1} = SolverLQNS(myLQN);
AvgTable{1} = solver{1}.getAvgTable();
AvgTable{1}

useLQNSnaming = true;
AvgTable{2} = solver{1}.getAvgTable(useLQNSnaming);
AvgTable{2}


useLQNSnaming = true;
[AvgTable{3}, CallAvgTable{3}] = solver{1}.getRawAvgTables();
AvgTable{3}
CallAvgTable{3}
