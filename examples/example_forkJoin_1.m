clearvars -except exampleName;
model = Network('model');

source = Source(model,'Source');
queue1 = Queue(model,'Queue1',SchedStrategy.PS);
queue2 = Queue(model,'Queue2',SchedStrategy.PS);
fork = Fork(model,'Fork');
join = Join(model,'Join', fork);
sink = Sink(model,'Sink');

jobclass1 = OpenClass(model, 'class1');

source.setArrival(jobclass1, Exp(0.5));
queue1.setService(jobclass1, Exp(1.0));
queue2.setService(jobclass1, Exp(1.0));

P = zeros(6);
P(source,fork) = 1;
P(fork,queue1) = 1.0;
P(fork,queue2) = 1.0;
P(queue1,join) = 1.0;
P(queue2,join) = 1.0;
P(join,sink) = 1.0;

model.link(P);

solver = {};
solver{end+1} = SolverJMT(model,'seed',23000);
solver{end+1} = SolverMVA(model);

AvgTable = {};
for s=1:length(solver)
    AvgTable{end+1} = solver{s}.getAvgTable;
    AvgTable{s}
end
