function sntagged = snTagJob(sn, oc)
% oc: old class
sntagged = sn;
sntagged.nclasses = sntagged.nclasses - 1;
nc = sn.nclasses + 1; 
jobClassChain = find(sn.chains(:,oc));
sntagged.chains(jobClassChain,nc)=true;  
sntagged.classcap(nc)=sntagged.classcap(oc);  
sntagged.classprio(nc)=sntagged.classprio(oc);
sntagged.classnames(nc)=sprintf('%s.tagged-%d',sntagged.classnames(oc),nc);  
sntagged.csmask(nc,:)=sntagged.csmask(oc,:); 
sntagged.csmask(:,nc)=sntagged.csmask(:,oc); 
sntagged.isslc(nc)=sntagged.isslc(oc); 
for i=1:length(sntagged.lst)
    sntagged.lst{i}{nc} = sntagged.lst{i}{oc};
    sntagged.mu{i}{nc} = sntagged.mu{i}{oc}; 
end
sntagged.njobs(nc)=sntagged.njobs(oc);
if ~isinf(sntagged.njobs(nc))
    sntagged.nclosedjobs(nc)=sntagged.nclosedjobs(oc);
end
sntagged.phases(:,nc)=sntagged.phases(:,oc);
sntagged.phasessz(:,nc)=sntagged.phasessz(:,oc);
sntagged.phaseshift = [zeros(size(phases,1),1),cumsum(sntagged.phasessz,2)];
sntagged.pie={};        % probability of entry in each each service phase
sntagged.phi={};         % probability of service completion in each service phase,
sntagged.proc={};     % cell matrix of service and arrival process representations
sntagged.procid=[]; % service or arrival process type id
sntagged.rates=[];       % service rate for each job class in each station
sntagged.refstat=[];    % index of the reference node for each request class (Kx1 int)
sntagged.routing=[];     % routing strategy type
sntagged.rt=[];         % routing table with class switching
sntagged.rtorig={};         % linked routing table rtorig{r,s}(i,j)
sntagged.rtnodes=[];         % routing table with class switching
sntagged.rtfun = @nan; % local routing functions
sntagged.sched=[];       % scheduling strategy in each station
sntagged.schedid=[];       % scheduling strategy id in each station (optional)
sntagged.schedparam=[];       % scheduling weights in each station and class (optional)
sntagged.sync={};
sntagged.space={};    % state space
sntagged.state={};    % initial or current state
sntagged.stateprior={};  % prior distribution of initial or current state
sntagged.scv=[]; % squared coefficient of variation of service times (MxK)
sntagged.visits={};           % visits placed by classes at the resources
sntagged.varsparam={};     % parameters for local variables
end