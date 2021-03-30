function [state, evtype, evclass, evjob] = parseTranState(fileArv, fileDep, nodePreload)
% [STATE, EVTYPE, EVCLASS, EVJOB] = PARSETRANSTATE(FILEARV, FILEDEP, NODEPRELOAD)

% Copyright (c) 2012-2021, Imperial College London
% All rights reserved.

load(fileArv,'jobArvTS','jobArvClassID','jobArvID');
load(fileDep,'jobDepTS','jobDepClassID','jobDepID');

%% compute joint state at station
nClasses = length(nodePreload);
state = [jobArvTS,zeros(length(jobArvTS),nClasses);
    jobDepTS,zeros(length(jobDepTS),nClasses)];

evtype = nan(size(state,1),1);
evclass = zeros(size(state,1),1);
evjob = zeros(size(state,1),1);

for i=1:size(jobArvTS,1)
    state(i,1+jobArvClassID(i))=+1;
    evtype(i) = EventType.ID_ARV;
    evclass(i) = jobArvClassID(i);
    evjob(i) = jobArvID(i);
end

for i=1:size(jobDepTS)
    state(length(jobArvTS)+i,1+jobDepClassID(i))=-1;
    evtype(length(jobArvTS)+i) = EventType.ID_DEP;
    evclass(length(jobArvTS)+i) = jobDepClassID(i);
    evjob(length(jobArvTS)+i) = jobDepID(i);
end
[state,I] = sortrows(state,1); % sort on timestamps
state = [0,nodePreload;state];
for j=2:(nClasses+1)
    state(:,j) = cumsum(state(:,j));%+nodePreload(j-1);
end
evtype = [EventType.ID_INIT; evtype(I)]; 
evclass = [NaN;evclass(I)];
evjob = [NaN;evjob(I)];

end