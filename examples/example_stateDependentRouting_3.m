clearvars -except exampleName;

model = Network('myModel');

% Block 1: nodes
source = Source(model, 'Source');
router = Router(model, 'Router');
queue1 = Queue(model, 'Queue1', SchedStrategy.FCFS);
queue2 = Queue(model, 'Queue2', SchedStrategy.FCFS);
sink = Sink(model, 'Sink');

% Block 2: classes
oclass = OpenClass(model, 'Class1');
source.setArrival(oclass, Exp(1));
queue1.setService(oclass, Exp(2));
queue2.setService(oclass, Exp(2));

% Block 3: topology
model.addLinks([source, router;...
    router, queue1; ...
    router, queue2; ...
    queue1, sink; ...
    queue2, sink]);
router.setRouting(oclass, RoutingStrategy.RROBIN);

solver{1} = SolverJMT(model,'seed',23000);
AvgTable{1} = solver{1}.getAvgNodeTable

%SolverCTMC(model,'cutoff',5).getAvgNodeTable
