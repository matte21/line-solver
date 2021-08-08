if ~isoctave(), clearvars -except exampleName; end
N = 16; % number of jobs
c = 2; % number of servers

model = Network('model');
node{1} = Delay(model, 'Delay');
node{2} = Queue(model, 'Queue1', SchedStrategy.FCFS);
jobclass{1} = ClosedClass(model, 'Class1', N, node{1}, 0);
node{1}.setService(jobclass{1}, Exp.fitMean(1.0)); % mean = 1
node{2}.setService(jobclass{1}, Exp.fitMean(1.5)); % mean = 1.5
node{2}.setNumberOfServers(c);

model.link(model.serialRouting(node));

solver = {};
msT=SolverNC(model).getAvgTable

ldmodel = Network('model');
node{1} = Delay(ldmodel, 'Delay');
node{2} = Queue(ldmodel, 'Queue1', SchedStrategy.FCFS);
jobclass{1} = ClosedClass(ldmodel, 'Class1', N, node{1}, 0);
node{1}.setService(jobclass{1}, Exp.fitMean(1.0)); % mean = 1
node{2}.setService(jobclass{1}, Exp.fitMean(1.5)); % mean = 1.5
node{2}.setLoadDependence(min(1:N,c)); % multi-server with c servers

ldmodel.link(ldmodel.serialRouting(node));

solver = {};
lldAvgTableDefault=SolverNC(ldmodel).getAvgTable
lldAvgTableRD=SolverNC(ldmodel,'method','rd').getAvgTable
lldAvgTableNRP=SolverNC(ldmodel,'method','nrp').getAvgTable
lldAvgTableNRL=SolverNC(ldmodel,'method','nrl').getAvgTable


