model = Network('myModel');
node{1} = Source(model, 'Source');
node{2} = Queue(model, 'Queue1', SchedStrategy.FCFS); node{2}.setNumServers(1);
node{3} = Queue(model, 'Queue2', SchedStrategy.FCFS); node{3}.setNumServers(1);
node{4} = Sink(model, 'Sink');
jobclass{1} = OpenClass(model, 'Class1', 0);
node{1}.setArrival(jobclass{1}, Cox2.fitMeanAndSCV(12.000000,1.000000));
node{2}.setService(jobclass{1}, Cox2.fitMeanAndSCV(1.000000,1.000000));
node{3}.setService(jobclass{1}, Cox2.fitMeanAndSCV(1.000000,1.000000));
jobclass{2} = OpenClass(model, 'Class2', 0);
node{1}.setArrival(jobclass{2}, Cox2.fitMeanAndSCV(12.000000,1.000000));
node{2}.setService(jobclass{2}, Cox2.fitMeanAndSCV(1.000000,1.000000));
node{3}.setService(jobclass{2}, Cox2.fitMeanAndSCV(1.000000,1.000000));
P = cell(2);
P{1,1} = [0 1 0 0;0 0 0 0;0 0 0 1;0 0 0 0];
P{1,2} = [0 0 0 0;0 0 1 0;0 0 0 0;0 0 0 0];
P{2,1} = [0 0 0 0;0 0 0 0;0 0 0 1;0 0 0 0];
P{2,2} = [0 1 0 0;0 0 1 0;0 0 0 0;0 0 0 0];
model.link(P);
%%
RDfluid = SolverFluid(model).getCdfRespT()
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