% similar to example_forkJoin_1 but closed
if ~isoctave(), clearvars -except exampleName; end
model = Network('model');

delay = Delay(model,'Delay');
queue1 = Queue(model,'Queue1',SchedStrategy.PS);
queue2 = Queue(model,'Queue2',SchedStrategy.PS);
fork = Fork(model,'Fork');
join = Join(model,'Join');

jobclass1 = ClosedClass(model, 'class1', 5, delay);

delay.setService(jobclass1, Exp(1.0));
queue1.setService(jobclass1, Exp(1.0));
queue2.setService(jobclass1, Exp(1.0));

P = zeros(5);
P(delay,fork) = 1;
P(fork,queue1) = 1.0;
P(fork,queue2) = 1.0;
P(queue1,join) = 1.0;
P(queue2,join) = 1.0;
P(join,delay) = 1.0;

model.link(P);
solver = {};
solver{end+1} = SolverJMT(model,'seed',23000);

AvgTable = {};
AvgTable{end+1} = solver{end}.getAvgTable;
AvgTable{end}
