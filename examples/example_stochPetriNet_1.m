if ~isoctave(), clearvars -except exampleName; end 
model = Network('model');

%% Nodes
node{1} = Source(model,'Source');
node{2} = Sink(model,'Sink');
node{3} = Place(model, 'P1');
node{4} = Place(model, 'P2');
node{5} = Place(model, 'P3');
node{6} = Place(model, 'P4');
node{7} = Place(model, 'P5');
node{8} = Place(model, 'P6');
node{9} = Place(model, 'P7');

node{10} = Transition(model, 'T1');
node{11} = Transition(model, 'T2');
node{12} = Transition(model, 'T3');
node{13} = Transition(model, 'T4');
node{14} = Transition(model, 'T5');
node{15} = Transition(model, 'T6');
node{16} = Transition(model, 'T7');

% Source
jobclass{1} = OpenClass(model, 'Class1', 0);
node{1}.setArrival(jobclass{1}, Exp(1));

%% Routing 
M = model.getNumberOfStations();
K = model.getNumberOfClasses();

P = cell(K,K);

P{1,1} = [0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0;
          0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0;
          0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0;
          0,0,0,0,0,0,0,0,0,0,1,1,0,0,0,0;
          0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0;
          0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0;
          0,0,0,0,0,0,0,0,0,0,0,0,1,1,0,0;
          0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,0;
          0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1;
          0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0;
          0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0;
          0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0;
          0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,0;
          0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0;
          0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0;
          0,1,1,0,0,0,1,0,0,0,0,0,0,0,0,0;];
model.link(P);

%% Parameterisation 


% T1
node{10}.addMode('Mode1');
node{10}.init();
node{10}.setDistribution(1,Exp(4));
node{10}.setEnablingConditions(1,jobclass{1},node{3},1);
node{10}.setFiringOutcome(1,jobclass{1},node{4},1);

% T2
node{11}.addMode('Mode1');
node{11}.init();
node{11}.setEnablingConditions(1,jobclass{1},node{4},1);
node{11}.setFiringOutcome(1,jobclass{1},node{5},1);
node{11}.setTimingStrategy(1,TimingStrategy.IMMEDIATE);
node{11}.setFiringPriorities(1,1);
node{11}.setFiringWeights(1,1);

% T3
node{12}.addMode('Mode1');
node{12}.init();
node{12}.setEnablingConditions(1,jobclass{1},node{4},1);
node{12}.setFiringOutcome(1,jobclass{1},node{6},1);
node{12}.setTimingStrategy(1,TimingStrategy.IMMEDIATE);
node{12}.setFiringPriorities(1,1);
% node{12}.setFiringWeights(1,0.6);
node{12}.setFiringPriorities(1,1);

% T4
node{13}.addMode('Mode1');
node{13}.init();
node{13}.setEnablingConditions(1,jobclass{1},node{5},1);
node{13}.setEnablingConditions(1,jobclass{1},node{7},1);
node{13}.setFiringOutcome(1,jobclass{1},node{7},1);
node{13}.setFiringOutcome(1,jobclass{1},node{8},1);
node{13}.setTimingStrategy(1,TimingStrategy.IMMEDIATE);
node{13}.setFiringPriorities(1,1);

% T5
node{14}.addMode('Mode1');
node{14}.init();
node{14}.setEnablingConditions(1,jobclass{1},node{6},1);
node{14}.setEnablingConditions(1,jobclass{1},node{7},1);
node{14}.setFiringOutcome(1,jobclass{1},node{9},1);
node{14}.setInhibitingConditions(1,jobclass{1},node{8},1);
node{14}.setTimingStrategy(1,TimingStrategy.IMMEDIATE);
node{14}.setFiringPriorities(1,1);

% T6
node{15}.addMode('Mode1');
node{15}.init();
node{15}.setDistribution(1,Erlang(2,2));
node{15}.setEnablingConditions(1,jobclass{1},node{8},1);
node{15}.setFiringOutcome(1,jobclass{1},node{3},1);

% T7
node{16}.addMode('Mode1');
node{16}.init();
node{16}.setDistribution(1,Exp(2));
node{16}.setEnablingConditions(1,jobclass{1},node{9},1);
node{16}.setFiringOutcome(1,jobclass{1},node{3},1);
node{16}.setFiringOutcome(1,jobclass{1},node{7},1);

%% Set Initial State    
node{1}.setState(0);
node{3}.setState(2);
node{4}.setState(0);
node{5}.setState(0);
node{6}.setState(0);
node{7}.setState(1);
node{8}.setState(0);
node{9}.setState(0);

state = model.getState;

%% Solver
options = Solver.defaultOptions;
options.keep=2;
options.verbose=1;
options.cutoff = 10;
options.seed = 23000;

% options.hide_immediate=1;
% options.is_pn=1;
% options.samples=2e4;

% All stations must be initialised.     
% initial_state = [0;2;0;0;0;1;0;0];

% solver = SolverCTMC(model, options);
% solver.getAvgTable();

 solver = SolverJMT(model,options);
 solver.getAvgTable()
