model = Network('myModel');

%% Block 1: nodes
node{1} = Source(model, 'Source');
node{2} = Queue(model, 'Queue1', SchedStrategy.FCFS);
node{3} = Queue(model, 'Queue2', SchedStrategy.FCFS);
node{4} = Sink(model, 'Sink');
node{5} = ClassSwitch(model, 'CS_Queue1_to_Queue2', eye(2)); % Class switching is embedded in the routing matrix P 
node{6} = ClassSwitch(model, 'CS_Queue2_to_Sink', eye(2)); % Class switching is embedded in the routing matrix P 

%% Block 2: classes
jobclass{1} = OpenClass(model, 'Class1', 0);
jobclass{2} = OpenClass(model, 'Class2', 0);

node{1}.setArrival(jobclass{1}, Exp.fitMean(12.000000)); % (Source,Class1)
node{1}.setArrival(jobclass{2}, Exp.fitMean(12.000000)); % (Source,Class2)
node{2}.setService(jobclass{1}, Exp.fitMean(1.000000)); % (Queue1,Class1)
node{2}.setService(jobclass{2}, Exp.fitMean(1.000000)); % (Queue1,Class2)
node{3}.setService(jobclass{1}, Exp.fitMean(1.000000)); % (Queue2,Class1)
node{3}.setService(jobclass{2}, Exp.fitMean(1.000000)); % (Queue2,Class2)

%% Block 3: topology
P = model.initRoutingMatrix(); % initialize routing matrix 
P{1,1}(1,2) = 1; % (Source,Class1) -> (Queue1,Class1)
P{1,1}(2,5) = 1; % (Queue1,Class1) -> (CS_Queue1_to_Queue2,Class1)
P{1,1}(3,6) = 1; % (Queue2,Class1) -> (CS_Queue2_to_Sink,Class1)
P{1,1}(6,4) = 1; % (CS_Queue2_to_Sink,Class1) -> (Sink,Class1)
P{1,2}(5,3) = 1; % (CS_Queue1_to_Queue2,Class1) -> (Queue2,Class2)
P{2,1}(6,4) = 1; % (CS_Queue2_to_Sink,Class2) -> (Sink,Class1)
P{2,2}(1,2) = 1; % (Source,Class2) -> (Queue1,Class2)
P{2,2}(2,5) = 1; % (Queue1,Class2) -> (CS_Queue1_to_Queue2,Class2)
P{2,2}(3,6) = 1; % (Queue2,Class2) -> (CS_Queue2_to_Sink,Class2)
P{2,2}(5,3) = 1; % (CS_Queue1_to_Queue2,Class2) -> (Queue2,Class2)
model.link(P);

%%
options = SolverFluid.defaultOptions;
options.iter_max = 300;
RDfluid = SolverFluid(model,options).getCdfRespT()
jmtoptions = SolverJMT.defaultOptions;
jmtoptions.samples = 1e4;
jmtoptions.seed = 23000;
RDsim = SolverJMT(model, jmtoptions).getTranCdfRespT();

%%
figure;
for i=1:model.getNumberOfStations
    subplot(model.getNumberOfStations,2,2*(i-1)+1)
    semilogx(RDsim{i,1}(:,2),1-RDsim{i,1}(:,1),'r')
    hold all;
    semilogx(RDfluid{i,1}(:,2),1-RDfluid{i,1}(:,1),'--')
    legend('jmt-transient','fluid-steady','Location','Best');
    title(['Tail: Node ',num2str(i),', Class ',num2str(1),', ',node{i}.serviceProcess{1}.name, ' service']);

    subplot(model.getNumberOfStations,2,2*(i-1)+2)
    semilogx(RDsim{i,2}(:,2),1-RDsim{i,2}(:,1),'r')
    hold all;
    semilogx(RDfluid{i,2}(:,2),1-RDfluid{i,2}(:,1),'--')
    legend('jmt-transient','fluid-steady','Location','Best');
    title(['Tail: Node ',num2str(i),', Class ',num2str(2),', ',node{i}.serviceProcess{2}.name, ' service']);
end

%%
for i=1:model.getNumberOfStations
    for c=1:model.getNumberOfClasses
        AvgRespTfromCDFfluid(i,c) = diff(RDfluid{i,c}(:,1))'*RDfluid{i,c}(2:end,2);
        AvgRespTfromCDFsim(i,c) = diff(RDsim{i,c}(:,1))'*RDsim{i,c}(2:end,2);
    end
end