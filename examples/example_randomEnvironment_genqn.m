function sn = example_randomEnvironment_gensn(rate, N)
%% sn1
sn = Network('qn1');

node{1} = Delay(sn, 'Queue1');
node{2} = Queue(sn, 'Queue2', SchedStrategy.PS);


jobclass{1} = ClosedClass(sn, 'Class1', N, node{1}, 0);

node{1}.setService(jobclass{1}, Exp(rate(1)));
node{2}.setService(jobclass{1}, Exp(rate(2)));

K = 1;
P = cell(K,K);
P{1} = circul(length(node));

sn.link(P);
end
