function qn = PMIF2QN(filename,verbose)
% Copyright (c) 2012-2019, Imperial College London
% All rights reserved.

if nargin == 1; verbose = 0; end

qn = PMIF.parseXML(filename,verbose);

if ~isempty(qn)
%% build CQN model
% transformation of scheduling policies
schedTranslate = {  'IS',   SchedStrategy.INF;
                    'FCFS', SchedStrategy.FCFS;
                    'PS',   SchedStrategy.PS};

% extract basic information 
Ms = length(qn.servers);
Mw = length(qn.workUnitServers);
M = Ms + Mw;

listServerIDs = cell(M,1);
for i = 1:Ms
    listServerIDs{i} = qn.servers(i).name;
end
for i = 1:Mw
    listServerIDs{Ms+i} = qn.workUnitServers(i).name;
end

K = length(qn.closedWorkloads);
listClasses = cell(K,1);
for i = 1:K
    listClasses{i} = qn.closedWorkloads(i).name;
end

P = zeros(M*K,M*K);
S = zeros(M,1);
rates = zeros(M,K); 
sched = cell(M,1);
NK = zeros(K,1); 
chains = eye(K);
refstat = zeros(K,1); 
stationnames = listServerIDs;
classnames = listClasses; 

% extract information from closedWorkloads
for k = 1:K
    NK(k) = qn.closedWorkloads(k).numberJobs;
    myRefNode = findstring(stationnames, qn.closedWorkloads(k).thinkDevice);
    refstat(k) =  myRefNode;
    rates(myRefNode, k) = 1/qn.closedWorkloads(k).thinkTime; 
    
    %routing
    for r = 1:size(qn.closedWorkloads(k).transits,1)
        dest = findstring(stationnames,  qn.closedWorkloads(k).transits{r,1} ) ; 
        P((myRefNode-1)*K+k, (dest-1)*K+k) = qn.closedWorkloads(k).transits{r,2};
    end
end

N = sum(NK(isfinite(NK))); 

% extract information from servers
for i = 1:Ms
    sched{i} = schedTranslate{findstring(schedTranslate(:,1),qn.servers(i).scheduling), 2 };
    if strcmp(sched{i}, SchedStrategy.INF)
        S(i) = Inf;
    else
        S(i) = qn.servers(i).quantity;
    end
end
    
for i = 1:Mw
    sched{Ms+i} = schedTranslate{findstring(schedTranslate(:,1),qn.workUnitServers(i).scheduling), 2 };
    if strcmp(sched{Ms+i}, SchedStrategy.INF)
        S(Ms+i) = Inf;
    else
        S(Ms+i) = qn.workUnitServers(i).quantity;
    end
end


%extract information from demandServiceRequest
for j = 1:length(qn.demandServiceRequests)
    % service rate
    k = findstring(classnames, qn.demandServiceRequests(j).workloadName );
    i = findstring(stationnames, qn.demandServiceRequests(j).serverID );
    rates(i,k) = qn.demandServiceRequests(j).serviceDemand / qn.demandServiceRequests(j).numberVisits; 
    
    %routing
    for r = 1:size(qn.demandServiceRequests(j).transits,1)
        dest = findstring(stationnames,  qn.demandServiceRequests(j).transits{r,1} ) ; 
        P((i-1)*K+k, (dest-1)*K+k) = qn.demandServiceRequests(j).transits{r,2};
    end
end

%extract information from workUnitServiceRequest
for j = 1:length(qn.workUnitServiceRequests)
    % service rate
    k = findstring(classnames, qn.workUnitServiceRequests(j).workloadName );
    i = findstring(stationnames, qn.workUnitServiceRequests(j).serverID );
    % work-unit-servers specify their own service time - indexed from Ms+1 to Ms + Mw in the list of servers
    rates(i,k) = 1 / ( qn.workUnitServers(i-Ms).serviceTime * qn.workUnitServiceRequests(j).numberVisits ); 
    
    %routing
    for r = 1:size(qn.workUnitServiceRequests(j).transits,1)
        dest = findstring(stationnames,  qn.workUnitServiceRequests(j).transits{r,1} ) ; 
        P((i-1)*K+k, (dest-1)*K+k) = qn.workUnitServiceRequests(j).transits{r,2};
    end
end

%extract information from timeServiceRequest
for j = 1:length(qn.timeServiceRequests)
    % service rate
    k = findstring(classnames, qn.timeServiceRequests(j).workloadName );
    i = findstring(stationnames, qn.timeServiceRequests(j).serverID );
    rates(i,k) = qn.timeServiceRequests(j).serviceDemand / qn.timeServiceRequests(j).numberVisits; 
    
    %routing
    for r = 1:size(qn.timeServiceRequests(j).transits,1)
        dest = findstring(stationnames,  qn.timeServiceRequests(j).transits{r,1} ) ; 
        P((i-1)*K+k, (dest-1)*K+k) = qn.timeServiceRequests(j).transits{r,2};
    end
end


qn = NetworkStruct(M, K, N, S, rates, sched, P, NK, chains, refstat,nodenames, stationnames, classnames);


else
   disp('Error: XML file empty or nonexistent');
   qn = [];
end

