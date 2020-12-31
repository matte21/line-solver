%% This example is temporarily disabled
if ~isoctave(), clearvars -except exampleName; end
fprintf(1,'This example illustrates the solution of a moderately large LQN.\n')

cwd = fileparts(which(mfilename));
model = LayeredNetwork.parseXML([cwd,filesep,'ofbizExample.xml']);

options = SolverLQNS.defaultOptions;
options.keep = true; % uncomment to keep the intermediate XML files generates while translating the model to LQNS

%% Solve with LN without initialization
lnsolver = SolverLN(model, @(x) SolverNC(x,'verbose',false));
Tnoinit = tic;
AvgTable = lnsolver.getAvgTable;
AvgTable
Tnoinit = toc(Tnoinit)
