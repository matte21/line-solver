function subnetwork = mucache_generate_subnetwork(model,pHit)

subnetwork = Network('SubNetwork');
classnumber = size(model.classes,1);
stationnumber = size(model.stations,1);
class = {};

maindelay = Delay(subnetwork,'MainDelay');
postproc = Queue(subnetwork,'PostProc',SchedStrategy.fromText(model.stations{2}.schedStrategy));

for i = 1:classnumber
    class{i} = ClosedClass(subnetwork, model.classes{i}.name, model.classes{i}.population, maindelay, 0);
    maindelay.setService(class{i},model.stations{1}.serviceProcess{i});
    postproc.setService(class{i},model.stations{2}.serviceProcess{i});
end

P = cellzeros(classnumber,classnumber,stationnumber,stationnumber);
P{class{1},class{2}}(1,1) = 1;
P{class{2},class{3}}(1,1) = 1;
P{class{3},class{4}}(1,2) = pHit;
P{class{3},class{5}}(1,2) = 1-pHit;
P{class{5},class{6}}(2,2) = 1;
P{class{4},class{1}}(2,1) = 1;
P{class{6},class{1}}(2,1) = 1;

subnetwork.link(P);
end