% cache with state dependent routing
clearvars -except exampleName;

model = Network('model');

n = 5; % number of items
m = 2; % cache capacity 

source = Source(model, 'Source');
cacheNode = Cache(model, 'Cache', n, m, ReplacementStrategy.FIFO);
delay1 = Delay(model,'Delay1');
delay2 = Delay(model,'Delay2');
sink = Sink(model, 'Sink');

jobClass = OpenClass(model, 'InitClass', 0);
hitClass = OpenClass(model, 'HitClass', 0);
missClass = OpenClass(model, 'MissClass', 0);

source.setArrival(jobClass, Exp(2));

delay1.setService(hitClass, Exp(10));
delay1.setService(missClass, Exp(1));
delay2.setService(hitClass, Exp(20));
delay2.setService(missClass, Exp(2));

pAccess = DiscreteSampler((1/n)*ones(1,n));  % uniform item references
cacheNode.setRead(jobClass, pAccess);

cacheNode.setHitClass(jobClass, hitClass);
cacheNode.setMissClass(jobClass, missClass);

model.addLink(source, cacheNode);
model.addLink(cacheNode, delay1);
model.addLink(cacheNode, delay2);
model.addLink(delay1, sink);
model.addLink(delay2, sink);

source.setProbRouting(jobClass, cacheNode, 1.0);
try
cacheNode.setRouting(hitClass,RoutingStrategy.RROBIN);
catch ME
    line_printf('The example first illustrates and invalid routing setup for a cache that triggers the following exception:');
    line_printf('%s',ME.message);
    line_printf('We now illustrate the correct setup of the same model.');
end
% cacheNode.setRouting(missClass,RoutingStrategy.RROBIN);
% delay1.setProbRouting(hitClass, sink, 1.0);
% delay1.setProbRouting(missClass, sink, 1.0);
% delay2.setProbRouting(hitClass, sink, 1.0);
% delay2.setProbRouting(missClass, sink, 1.0);
% 
% solver{1} = SolverCTMC(model,'keep',false,'cutoff',1,'seed',1);
% AvgTable{1} = solver{1}.getAvgNodeTable; AvgTable{1}
% 
% model.reset;
% solver{2} = SolverSSA(model,'samples',1e4,'verbose',true,'method','serial','seed',1);
% AvgTable{2} = solver{2}.getAvgNodeTable; AvgTable{2}
% 
% model.reset;
% solver{3} = SolverMVA(model,'seed',1);
% AvgTable{3} = solver{3}.getAvgNodeTable; AvgTable{3}
% 
% model.reset;
% solver{4} = SolverNC(model,'seed',1);
% AvgTable{4} = solver{4}.getAvgNodeTable; AvgTable{4}
% 
% hitRatio=cacheNode.getHitRatio
% missRatio=cacheNode.getMissRatio

%%
% cache with state dependent routing
clearvars -except exampleName;

model = Network('model');

n = 5; % number of items
m = 2; % cache capacity 

source = Source(model, 'Source');
cacheNode = Cache(model, 'Cache', n, m, ReplacementStrategy.FIFO);
routerNode = Router(model, 'Router');
delay1 = Delay(model,'Delay1');
delay2 = Delay(model,'Delay2');
sink = Sink(model, 'Sink');

jobClass = OpenClass(model, 'InitClass', 0);
hitClass = OpenClass(model, 'HitClass', 0);
missClass = OpenClass(model, 'MissClass', 0);

source.setArrival(jobClass, Exp(2));
source.setArrival(hitClass, Disabled());
source.setArrival(missClass, Disabled());

delay1.setService(hitClass, Exp(10));
delay1.setService(missClass, Exp(1));
delay2.setService(hitClass, Exp(20));
delay2.setService(missClass, Exp(2));

pAccess = DiscreteSampler((1/n)*ones(1,n));  % uniform item references
cacheNode.setRead(jobClass, pAccess);
cacheNode.setHitClass(jobClass, hitClass);
cacheNode.setMissClass(jobClass, missClass);

model.addLink(source, cacheNode);
model.addLink(cacheNode, routerNode);
model.addLink(routerNode, delay1);
model.addLink(routerNode, delay2);
model.addLink(delay1, sink);
model.addLink(delay2, sink);

source.setProbRouting(jobClass, cacheNode, 1.0);

cacheNode.setRouting(jobClass, RoutingStrategy.RAND);
cacheNode.setProbRouting(hitClass, routerNode, 1.0);
cacheNode.setProbRouting(missClass, routerNode, 1.0);

routerNode.setRouting(hitClass,RoutingStrategy.RAND);
routerNode.setRouting(missClass,RoutingStrategy.RAND);

delay1.setProbRouting(hitClass, sink, 1.0);
delay1.setProbRouting(missClass, sink, 1.0);

delay2.setProbRouting(hitClass, sink, 1.0);
delay2.setProbRouting(missClass, sink, 1.0);

solver{1} = SolverCTMC(model,'keep',false,'cutoff',1,'seed',1);
AvgTable{1} = solver{1}.getAvgNodeTable; AvgTable{1}

model.reset;
solver{2} = SolverSSA(model,'samples',1e4,'verbose',true,'method','serial','seed',1);
AvgTable{2} = solver{2}.getAvgNodeTable; AvgTable{2}
%%
model.reset;
solver{3} = SolverMVA(model,'seed',1);
AvgTable{3} = solver{3}.getAvgNodeTable; AvgTable{3}

model.reset;
solver{4} = SolverNC(model,'seed',1);
AvgTable{4} = solver{4}.getAvgNodeTable; AvgTable{4}

hitRatio=cacheNode.getHitRatio
missRatio=cacheNode.getMissRatio