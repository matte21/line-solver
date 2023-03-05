clearvars -except exampleName;
model = Network('model');

node{1} = Queue(model, 'Queue0', SchedStrategy.PS); %Delay(model, 'Delay');
node{2} = Queue(model, 'Queue1', SchedStrategy.FCFS);
node{2}.setNumServers(3);

% Default: scheduling is set as FCFS everywhere, routing as Random
jobclass{1} = ClosedClass(model, 'Class1', 4, node{1}, 0);
jobclass{2} = ClosedClass(model, 'Class2', 2, node{1}, 0);

node{1}.setService(jobclass{1}, Exp(1));
node{1}.setService(jobclass{2}, Exp(1));

node{2}.setService(jobclass{1}, Exp(1));
node{2}.setService(jobclass{2}, Exp(10));

myP = model.initRoutingMatrix;
myP{1} = Network.serialRouting(node);
myP{2} = Network.serialRouting(node);
model.link(myP);
%
options = SolverQNS.defaultOptions;
%options.verbose = false;

solver = {};
solver{1} = SolverCTMC(model);
solver{end+1} =SolverQNS(model,'conway');
solver{end+1} =SolverQNS(model,'reiser');
solver{end+1} =SolverQNS(model,'rolia');
solver{end+1} =SolverQNS(model,'zhou');
options = SolverMVA.defaultOptions;
options.config.multiserver = 'softmin';
solver{end+1} = SolverMVA(model, options);
options.config.multiserver = 'seidmann';
solver{end+1} = SolverMVA(model, options);
solver{end+1} = SolverNC(model)

AvgTable = cell(1,length(solver));
for s=1:length(solver)
    fprintf(1,'SOLVER: %s\n',solver{s}.getName());    
    AvgTable{s} = solver{s}.getAvgTable();
    AvgTable{s}
end

