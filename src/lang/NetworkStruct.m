function qn=NetworkStruct()
 % Data structure representation for a Network object
 %
 % Copyright (c) 2012-2021, Imperial College London
 % All rights reserved.
 
 qn=[]; %faster than qn=struct();
 qn.cap=[];     % total buffer size
 qn.chains=[];     % binary CxK matrix where 1 in entry (i,j) indicates that class j is in chain i.
 qn.classcap=[];    % buffer size for each class
 qn.classnames={};  % name of each job class
 qn.classprio=[];       % scheduling priorities in each class (optional)
 qn.connmatrix=[]; % (i,j) entry if node i can route to node j
 qn.csmask=[]; % (r,s) entry if class r can switch into class s somewhere
 %forks;      % forks table from each station
 % (MKxMK matrix with integer entries), indexed first by
 % station, then by class
 qn.dropid=[]; % (i,r) gives the drop rule for class r at station i
 qn.isstatedep=[]; % state dependent routing
 qn.isstation=[]; % element i is true if node i is a station
 qn.isstateful=[]; % element i is true if node i is stateful
 qn.isslc=[]; % element r is true if class r self-loops at its reference station
 qn.lst={}; % laplace-stieltjes transform
 qn.mu={};          % service rate in each service phase, for each job class in each station
 % (MxK cell with n_{i,k}x1 double entries)
 qn.nchains=[];           % number of chains (int)
 qn.nclasses=[];          % number of classes (int)
 qn.nclosedjobs=[];          % total population (int)
 qn.njobs=[];             % initial distribution of jobs in classes (Kx1 int)
 qn.nnodes=[]; % number of nodes (Mn int)
 qn.nservers=[];   % number of servers per station (Mx1 int)
 qn.nstations=[];  % number of stations (int)
 qn.nstateful=[];  % number of stations (int)
 qn.nvars=[]; % number of local variables
 qn.nodenames={};   % name of each node
 qn.nodevisits={};  % visits placed by classes at the nodes
 qn.nodetype=[]; % server type in each node
 qn.phases=[]; % number of phases in each service or arrival process
 qn.phasessz=[]; % number of phases
 qn.phaseshift=[]; % shift for phases
 qn.pie={};        % probability of entry in each each service phase
 qn.phi={};         % probability of service completion in each service phase,
 % for each job class in each station
 % (MxK cell with n_{i,k}x1 double entries)
 qn.proc={};     % cell matrix of service and arrival process representations
 qn.procid=[]; % service or arrival process type id
 qn.rates=[];       % service rate for each job class in each station
 qn.refstat=[];    % index of the reference node for each request class (Kx1 int)
 qn.routing=[];     % routing strategy type
 qn.rt=[];         % routing table with class switching
 % (M*K)x(M*K) matrix with double entries), indexed first by
 % station, then by class
 qn.rtorig={};         % linked routing table rtorig{r,s}(i,j)
 qn.rtnodes=[];         % routing table with class switching
 % (Mn*K)x(Mn*K) matrix with double entries), indexed first by
 % node, then by class
 qn.rtfun = @nan; % local routing functions
 % (Mn*K)x(Mn*K) matrix with double entries), indexed first by
 % station, then by class
 qn.sched=[];       % scheduling strategy in each station
 qn.schedid=[];       % scheduling strategy id in each station (optional)
 qn.schedparam=[];       % scheduling weights in each station and class (optional)
 qn.sync={};
 qn.space={};    % state space
 qn.state={};    % initial or current state
 qn.stateprior={};  % prior distribution of initial or current state
 qn.scv=[]; % squared coefficient of variation of service times (MxK)
 qn.visits={};           % visits placed by classes at the resources
 qn.varsparam={};     % parameters for local variables
 
 % hashing maps
 qn.nodeToStateful=[];
 qn.nodeToStation=[];
 qn.stationToNode=[];
 qn.stationToStateful=[];
 qn.statefulToNode=[];
end