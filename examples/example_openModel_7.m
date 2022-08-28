if ~isoctave(), clearvars -except exampleName; end 
%% a basic M/M/1 with explicit definition of a classswitch node

model = Network('mm1cs');

%% Block 1: nodes
node{1} = Source(model, 'Source 1');
node{2} = Queue(model, 'Queue 1', SchedStrategy.FCFS);
node{3} = Sink(model, 'Sink 1');
csmatrix = [0.3,0.7;1.0,0]; % element (i,j) = probability that class i switches to j
node{4} = ClassSwitch(model, 'ClassSwitch 1', csmatrix); % Class switching is embedded in the routing matrix P 

%% Block 2: classes
jobclass{1} = OpenClass(model, 'Class1', 0);
jobclass{2} = OpenClass(model, 'Class2', 0);

node{1}.setArrival(jobclass{1}, Exp.fitMean(10.000000)); % (Source 1,Class1)
node{1}.setArrival(jobclass{2}, Exp.fitMean(2.000000)); % (Source 1,Class2)
node{2}.setService(jobclass{1}, Exp.fitMean(1.000000)); % (Queue 1,Class1)
node{2}.setService(jobclass{2}, Exp.fitMean(1.000000)); % (Queue 1,Class2)

%% Block 3: topology
P = model.initRoutingMatrix(); % initialize routing matrix 
P{1,1}(1,4) = 1; % (Source 1,Class1) -> (ClassSwitch 1,Class1)
P{1,1}(2,3) = 1; % (Queue 1,Class1) -> (Sink 1,Class1)
P{1,1}(4,2) = 1; % (ClassSwitch 1,Class1) -> (Queue 1,Class1)
P{2,2}(1,4) = 1; % (Source 1,Class2) -> (ClassSwitch 1,Class2)
P{2,2}(2,3) = 1; % (Queue 1,Class2) -> (Sink 1,Class2)
P{2,2}(4,2) = 1; % (ClassSwitch 1,Class2) -> (Queue 1,Class2)
model.link(P);

SolverMVA(model).getAvgChainTable