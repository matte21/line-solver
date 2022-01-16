function [Qfull, Ufull, Rfull, Tfull, ymean, Qfull_t, Ufull_t, Tfull_t, ymean_t, t,iters,runtime] = solver_fluid_analyzer_inner(sn, options)
% [QFULL, UFULL, RFULL, TFULL, YMEAN, QFULL_T, UFULL_T, TFULL_T, YMEAN_T, T,ITERS,RUNTIME] = SOLVER_FLUID_ANALYZER_INNER(QN, OPTIONS)

% Copyright (c) 2012-2022, Imperial College London
% All rights reserved.
chains = sn.chains;

% inner iteration of fluid analysis
[Q,ymean,Qfull_t,Ufull_t,ymean_t,t,iters,runtime] = solver_fluid(sn, options);

%% assumes the existence of a delay node through which all classes pass
delayNodes = zeros(1,sn.nstations);
delayrefstat = zeros(1,sn.nstations); % delay nodes that are also reference nodes
for i = 1:sn.nstations
    if strcmp(sn.schedid(i),SchedStrategy.ID_INF)
        delayNodes(i) = 1;
    end
end
for k = 1:sn.nclasses
    if sn.refstat(k) > 0 % artificial classes do not need to have a reference node
        delayrefstat(sn.refstat(k)) = 1;
    end
end

%% simpler version: no chain analysis
M = sn.nstations;
K = sn.nclasses;
refstat = sn.refstat;
Lambda = sn.mu;
phi = sn.phi;
phases = sn.phases;

%Qlength for all stations, classes,
Qfull = ymean{end};

%% Tput for all classes in each station
Rlittle = zeros(sn.nstations,sn.nclasses); % throughput of every class at each station
Tfull = zeros(sn.nstations,sn.nclasses); % throughput of every class at each station
Tfull_t = cell(size(Tfull));
for i=1:size(Tfull_t,1)
    for j=1:size(Tfull_t,2)
        Tfull_t{i,j} = 0;
    end
end
Xservice = cell(M,K); %throughput per class, station and phase
for i = 1:sn.nstations
    if delayNodes(i) == 1
        for k = 1:sn.nclasses
            idx = sum(sum(phases(1:i-1,:))) + sum( phases(i,1:k-1) );
            Xservice{i,k} = zeros(phases(i,k),1);
            for f = 1:phases(i,k)         
                Tfull(i,k) = Tfull(i,k) + Qfull(idx+f)*Lambda{i}{k}(f)*phi{i}{k}(f);
                Tfull_t{i,k} = Tfull_t{i,k} + Qfull_t{i,k}*Lambda{i}{k}(f)*phi{i}{k}(f);
                Xservice{i,k}(f) = Qfull(idx+f)*Lambda{i}{k}(f);
            end
        end
    else
        xi = sum(Q(i,:)); %number of jobs in the station
        xi_t = Qfull_t{i,1};
        for r=2:size(Qfull_t,2)
            xi_t = xi_t + Qfull_t{i,r};
        end
        
        if xi>0
            switch sn.schedid(i)
                case SchedStrategy.ID_FCFS
                    wni = 1e-2;
                    w = zeros(1,sn.nclasses);
                    for k = 1:sn.nclasses
                        idx = sum(sum(phases(1:i-1,:))) + sum( phases(i,1:k-1) );
                        wi(k) = map_mean(sn.proc{i}{k});
                        wni = wni + wi(k)*sum(Qfull((idx+1):(idx+phases(i,k))));
                    end
                    wni_t = 0*Qfull_t{i,1};
                    for r=1:sn.nclasses
                        wni_t = wni_t + wi(r)* Qfull_t{i,r};
                    end
                    
            end
            
            for k = 1:sn.nclasses
                idx = sum(sum(phases(1:i-1,:))) + sum( phases(i,1:k-1) );
                Xservice{i,k} = zeros(phases(i,k),1);
                for f = 1:phases(i,k)                    
                    switch sn.schedid(i)
                        case SchedStrategy.ID_EXT
                            if f==1
                                Tfull(i,k) = Tfull(i,k) + (1-sum(Qfull(idx+(2:phases(i,k)))))*Lambda{i}{k}(f)*phi{i}{k}(f);
                                Tfull_t{i,k} = Tfull_t{i,k} + (1-sum(ymean_t(:,idx+(2:phases(i,k))),2))*Lambda{i}{k}(f)*phi{i}{k}(f);
                                Xservice{i,k}(f) = (1-sum(Qfull(idx+(2:phases(i,k)))))*Lambda{i}{k}(f);
                            else
                                Tfull(i,k) = Tfull(i,k) + Qfull(idx+f)*Lambda{i}{k}(f)*phi{i}{k}(f);
                                Tfull_t{i,k} = Tfull_t{i,k} + ymean_t(:,idx+f)*Lambda{i}{k}(f)*phi{i}{k}(f);
                                Xservice{i,k}(f) = Qfull(idx+f)*Lambda{i}{k}(f);
                            end
                        case {SchedStrategy.ID_INF, SchedStrategy.ID_PS}
                            Tfull(i,k) = Tfull(i,k) + Qfull(idx+f)*Lambda{i}{k}(f)*phi{i}{k}(f)/xi*min(xi,sn.nservers(i));
                            Tfull_t{i,k} = Tfull_t{i,k} + ymean_t(:,idx+f)*Lambda{i}{k}(f)*phi{i}{k}(f)./xi_t.*min(xi_t,sn.nservers(i));
                            Xservice{i,k}(f) = Qfull(idx+f)*Lambda{i}{k}(f)/xi*min(xi,sn.nservers(i));
                        case SchedStrategy.ID_DPS
                            w = sn.schedparam(i,:);
                            wxi = w*Q(i,:)'; %number of jobs in the station
                            wxi_t = w(1)*Qfull_t{i,1};
                            for r=2:size(Qfull_t,2)
                                wxi_t = wxi_t + w(r)*Qfull_t{i,r};
                            end
                            Tfull(i,k) = Tfull(i,k) + Qfull(idx+f)*Lambda{i}{k}(f)*phi{i}{k}(f)*w(k)/wxi*min(xi,sn.nservers(i));
                            Tfull_t{i,k} = Tfull_t{i,k} + ymean_t(:,idx+f)*Lambda{i}{k}(f)*phi{i}{k}(f)*w(k)./wxi_t.*min(xi_t,sn.nservers(i));
                            Xservice{i,k}(f) = Qfull(idx+f)*Lambda{i}{k}(f)*w(k)/wxi*min(xi,sn.nservers(i));
                        case {SchedStrategy.ID_FCFS, SchedStrategy.ID_SIRO}
                            switch options.method
                                case {'default','stateindep'}
                                    Tfull(i,k) = Tfull(i,k) + Qfull(idx+f)*Lambda{i}{k}(f)*phi{i}{k}(f)/xi*min(xi,sn.nservers(i));
                                    Tfull_t{i,k} = Tfull_t{i,k} + ymean_t(:,idx+f)*Lambda{i}{k}(f)*phi{i}{k}(f)./xi_t.*min(xi_t,sn.nservers(i));
                                    Xservice{i,k}(f) = Qfull(idx+f)*Lambda{i}{k}(f)/xi*min(xi,sn.nservers(i));
                                case 'statedep'
                                    Tfull(i,k) = Tfull(i,k) + Qfull(idx+f)*Lambda{i}{k}(f)*phi{i}{k}(f)*wi(k)/wni*min(xi,sn.nservers(i));
                                    Tfull_t{i,k} = Tfull_t{i,k} + ymean_t(:,idx+f)*Lambda{i}{k}(f)*phi{i}{k}(f)./xi_t.*min(xi_t,sn.nservers(i));
                                    Xservice{i,k}(f) = Qfull(idx+f)*Lambda{i}{k}(f)*wi(k)/wni*min(xi,sn.nservers(i));
                                    
                                    %Tfull(i,k) = Tfull(i,k) + Qfull(idx+f)*Lambda{i}{k}(f)*phi{i}{k}(f)*min(xi,sn.nservers(i))*wi(k);
                                    %Tfull_t{i,k} = Tfull_t{i,k} + ymean_t(:,idx+f)*Lambda{i}{k}(f)*phi{i}{k}(f).*min(xi_t,sn.nservers(i)) * wi(k);
                                    %Xservice{i,k}(f) = Qfull(idx+f)*Lambda{i}{k}(f)*min(xi,sn.nservers(i))*wi(k);
                                    
                                    %                                    Tfull(i,k) = Tfull(i,k) + Qfull(idx+f)*Lambda{i}{k}(f)*phi{i}{k}(f)*min(xi,sn.nservers(i))*wi(k)/wni;
                                    %                                    Tfull_t{i,k} = Tfull_t{i,k} + ymean_t(:,idx+f)*Lambda{i}{k}(f)*phi{i}{k}(f).*min(xi_t,sn.nservers(i)) * wi(k)/wni;
                                    %                                    Xservice{i,k}(f) = Qfull(idx+f)*Lambda{i}{k}(f)*min(xi,sn.nservers(i))*wi(k)/wni;
                            end
                        otherwise
                            line_error(mfilename,'Unsupported scheduling policy');
                    end
                end
            end
        end
    end
end
for i=1:size(Tfull_t,1)
    for j=1:size(Tfull_t,2)
        if numel(Tfull_t{i,j}) == 1
            Tfull_t{i,j} = Tfull_t{i,j} * ones(size(ymean_t(:,1),1),1);
        end
    end
end
%% response times
origK = size(chains,1);
% This is approximate, Little's law does not hold in transient
R = zeros(sn.nstations, sn.nclasses);
for i = 1:sn.nstations
    R(i, Tfull(i,:)>0) = Q(i,Tfull(i,:)>0) ./ Tfull(i,Tfull(i,:)>0);
end
%R = Rlittle;
%Tfull = Tlittle;
newR = zeros(sn.nstations,origK);
X = zeros(1,origK);
newQ = zeros(sn.nstations,origK);
% determine eventual probability of visiting each station in each class (expected number of visits)
% weight response time of each original class with the expented number of
% visits to each station in each associated artificial class
idxNR = reshape(1:sn.nstations*sn.nclasses, sn.nclasses, sn.nstations); %indices of non-delay (non-reference) nodes
idxNR = reshape(idxNR(:,delayrefstat==0),1,[]);
rtTrans = sn.rt(idxNR,idxNR); %transient transition matrix for non-reference nodes
eventualVisit = inv( eye(size(rtTrans)) - rtTrans );
idxOrigClasses = zeros(origK,1);

for k = 1:origK
    idxOrigClasses(k) = find(chains(k,:),1);
    refNode = refstat(idxOrigClasses(k));
    
    eventualVisitProb = reshape( sn.rt((refNode-1)*sn.nclasses+k,idxNR)*eventualVisit, sn.nclasses , sn.nstations-sum(delayrefstat>0) )'; %#ok<MINV> %probability of eventual visit
    eventualVisitProb = eventualVisitProb(:,chains(k,:)==1);
    
    newR(refNode,k) = sum( R(refNode,chains(k,:)==1),2 );
    newR(delayrefstat==0,k) = sum( R(delayrefstat==0,chains(k,:)==1).*eventualVisitProb,  2 );
    newR(refNode,chains(k,:)==1) = R(refNode,chains(k,:)==1);
    newR(delayrefstat==0,chains(k,:)==1) = R(delayrefstat==0,chains(k,:)==1).*eventualVisitProb;
    
    %X(k,find(chains(k,:)))= sum(Tfull(refNode,find(chains(k,:))));
    X(1,k) = sum( Tfull(refNode,chains(k,:)==1) );
    newQ(:,k) = sum( Q(:,chains(k,:)==1),2 );
end
Qfull = Q;
Rfull = R;

%% Utilization
Ufull = zeros(M,K);
for i =1:M
    for k = 1:K
        idx = Xservice{i,k}>0;
        Ufull(i,k) = sum(Xservice{i,k}(idx)./ Lambda{i}{k}(idx));
        switch sn.schedid(i)
            case SchedStrategy.ID_FCFS
                switch options.method
                    case 'statedep'                    
                        Tfull(i,k) = sum(Xservice{i,k}(idx));
                end
        end
    end
end

Ufull(delayNodes==0,:) = Ufull(delayNodes==0,:)./repmat(sn.nservers(delayNodes==0),1,K);

% for i = 1:sn.nstations
%     for k=1:sn.nclasses
%         c = find(sn.chains(:,k));
%         if delayNodes(i) == 1
%             Rlittle(i,k) = sn.visits{c}(i,k)*(1/sn.rates(i,k));
%         else
%             Rlittle(i,k) = sn.visits{c}(i,k)*(1/sn.rates(i,k))*sum(Qfull(i,:));
%         end
%     end
% end
% Rlittle(isnan(Rlittle)) = 0;
% Tlittle = Qfull ./ Rlittle; Tlittle(isnan(Tlittle)) = 0;
% Tfull = Tlittle;
% Rfull = Rlittle;

end
