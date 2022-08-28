if ~isoctave(), clearvars -except exampleName; end
fprintf(1,'This example illustrates the solution of a complext layered queueing network extracted from a BPMN model.\n')

cwd = fileparts(which(mfilename));
model = LayeredNetwork.parseXML([cwd,filesep,'example_layeredModel_6.xml']);

options = SolverLQNS.defaultOptions;
options.keep = true; % uncomment to keep the intermediate XML files generates while translating the model to LQNS

solver{1} = SolverLQNS(model);
AvgTable{1} = solver{1}.getAvgTable();
AvgTable{1}
%%
solver{2} = SolverLN(model,@SolverMVA);
AvgTable{2} = solver{2}.getAvgTable();
AvgTable{2}
