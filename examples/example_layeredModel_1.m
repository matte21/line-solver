if ~isoctave(), clearvars -except exampleName; end
fprintf(1,'This example illustrates the execution on a layered queueing network model.\n')
fprintf(1,'Performance indexes now refer to processors, tasks, entries, and activities.\n')
fprintf(1,'Indexes refer to the submodel (layer) where the processor or task acts as a server.\n')
fprintf(1,'NaN indexes indicate that the metric is not supported by the node type.\n')

cwd = fileparts(which(mfilename));
model = LayeredNetwork.parseXML([cwd,filesep,'example_layeredModel_1.xml']);

options = SolverLQNS.defaultOptions;
options.keep = true; % uncomment to keep the intermediate XML files generates while translating the model to LQNS

solver{1} = SolverLQNS(model);
AvgTable = solver{1}.getAvgTable();
AvgTable

useLQNSnaming = true;
AvgTable = solver{1}.getAvgTable(useLQNSnaming);
AvgTable


useLQNSnaming = true;
[AvgTable, CallAvgTable] = solver{1}.getRawAvgTables();
AvgTable
CallAvgTable
