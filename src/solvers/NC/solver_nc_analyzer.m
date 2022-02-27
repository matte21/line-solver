function [Q,U,R,T,C,X,lG,runtime] = solver_nc_analyzer(sn, options)
% [Q,U,R,T,C,X,LG,RUNTIME] = SOLVER_NC_ANALYZER(QN, OPTIONS)

% Copyright (c) 2012-2022, Imperial College London
% All rights reserved.

M = sn.nstations;    %number of stations
nservers = sn.nservers;
if max(nservers(nservers<Inf))>1 & strcmpi(options.method,'exact')
    line_error(mfilename,'NC solver cannot provide exact solutions for open or mixed queueing networks. Remove the ''exact'' option.');
end

NK = sn.njobs';  % initial population per class
schedid = sn.schedid;
C = sn.nchains;
SCV = sn.scv;
ST = 1 ./ sn.rates;
ST(isnan(ST))=0;
ST0=ST;

Nchain = zeros(1,C);
for c=1:C
    inchain = find(sn.chains(c,:));
    Nchain(c) = sum(NK(inchain)); %#ok<FNDSB>
end
Nt = sum(Nchain(isfinite(Nchain)));
openChains = find(isinf(Nchain));
closedChains = find(~isinf(Nchain));

eta_1 = zeros(1,M);
eta = ones(1,M);
ca_1 = ones(1,M);
if all(schedid~=SchedStrategy.ID_FCFS) options.iter_max=1; end
it = 0;
while max(abs(1-eta./eta_1)) > options.iter_tol && it < options.iter_max
    it = it + 1;
    eta_1 = eta;
    M = sn.nstations;    %number of stations
    K = sn.nclasses;    %number of classes
    C = sn.nchains;
    Lchain = zeros(M,C);
    STchain = zeros(M,C);
    
    SCVchain = zeros(M,C);
    refstatchain = zeros(C,1);
    lambda = zeros(1,C);
    [~,~,Vchain,alpha,Nchain,SCVchain,refstatchain] = snGetDemandsChain(sn);
    for c=1:C
        inchain = find(sn.chains(c,:));
        isOpenChain = any(isinf(sn.njobs(inchain)));
        for i=1:M
            % we assume that the visits in L(i,inchain) are equal to 1
            Lchain(i,c) = Vchain(i,c) * ST(i,inchain) * alpha(i,inchain)';
            STchain(i,c) = ST(i,inchain) * alpha(i,inchain)';
            if isOpenChain && i == sn.refstat(inchain(1)) % if this is a source ST = 1 / arrival rates
                lambda(c) = 1 ./ STchain(i,c);
            end
        end
    end
    
    STchain(~isfinite(STchain))=0;
    Lchain(~isfinite(Lchain))=0;
    Tstart = tic;
    
    Lms = zeros(M,C);
    Z = zeros(M,C);
    Zms = zeros(M,C);
    infServers = [];
    for i=1:M
        if isinf(nservers(i)) % infinite server
            infServers(end+1) = i;
            Lms(i,:) = 0;
            Z(i,:) = Lchain(i,:);
            Zms(i,:) = 0;
        else
            if strcmpi(options.method,'exact') && nservers(i)>1
                %options.method = 'default';
                line_warning(mfilename,sprintf('%s does not support exact multiserver yet. Switching to approximate method.', 'SolverNC'));
            end
            Lms(i,:) = Lchain(i,:) / nservers(i);
            Z(i,:) = 0;
            Zms(i,:) = Lchain(i,:) * (nservers(i)-1)/nservers(i);
        end
    end
    % step 1
    [lG, Xchain, Qchain] = pfqn_nc(lambda,Lms,Nchain,sum(Z,1)+sum(Zms,1), options);
    
    if sum(Zms,1) > Distrib.Zero
        % in this case, we need to use the iterative approximation below
        Xchain=[];
        Qchain=[];
    end
    
    % commented out, poor performance on bench_CQN_FCFS_rm_multiserver_hicv_midload
    % model 7 as it does not guarantee that the closed population is
    % constant
    %     % step 2 - reduce the artificial think time
    %     if any(S(isfinite(S)) > 1)
    %         Xchain = zeros(1,C);
    %         for r=1:C % we need the utilizations in step 2 so we determine tput
    %             Xchain(r) = exp(pfqn_nc(Lcorr,oner(Nchain,r),sum(Z,1)+sum(Zcorr,1), options) - lG);
    %         end
    %         for i=1:M
    %             if isinf(S(i)) % infinite server
    %                 % do nothing
    %             else
    %                 Zcorr(i,:) = max([0,(1-(Xchain*Lchain(i,:)'/S(i))^S(i))]) * Lchain(i,:) * (S(i)-1)/S(i);
    %             end
    %         end
    %         lG = pfqn_nc(Lcorr,Nchain,sum(Z,1)+sum(Zcorr,1), options); % update lG
    %     end
    
    if isempty(Xchain)
        Xchain=lambda;
        Qchain = zeros(M,C);
        for r=closedChains
            lGr(r) = pfqn_nc(lambda,Lms,oner(Nchain,r),sum(Z,1)+sum(Zms,1), options);
            Xchain(r) = exp(lGr(r) - lG);
            for i=1:M
                if Lchain(i,r)>0
                    if isinf(nservers(i)) % infinite server
                        Qchain(i,r) = Lchain(i,r) * Xchain(r);
                    else
                        % add repliaca of station i and move job of class r
                        % in separate class
                        lGar(i,r) = pfqn_nc([lambda,0],[Lms(setdiff(1:size(Lms,1),i),:),zeros(size(Lms,1)-1,1); Lms(i,:),1], [oner(Nchain,r),1], [sum(Z,1)+sum(Zms,1),0], options);
                        Qchain(i,r) = Zms(i,r) * Xchain(r) + Lms(i,r) * exp(lGar(i,r) - lG);
                    end
                end
            end
            Qchain(isnan(Qchain))=0;
        end
        for r=openChains
            for i=1:M
                Qchain(i,r) = lambda(r)*Lchain(i,r)/(1-lambda(openChains)*Lchain(i,openChains)'/nservers(i))*(1+sum(Qchain(i,closedChains)));
            end
        end
    else
        % just fill the delay servers
        for r=1:C
            for i=1:M
                if Lchain(i,r)>0
                    if isinf(nservers(i)) % infinite server
                        Qchain(i,r) = Lchain(i,r) * Xchain(r);
                    end
                end
            end
        end
    end
    
    if isnan(Xchain)
        line_warning(mfilename,'Normalizing constant computations produced a floating-point range exception. Model is likely too large.');
    end
    
    Z = sum(Z(1:M,:),1);
    
    Rchain = Qchain ./ repmat(Xchain,M,1) ./ Vchain;
    Rchain(infServers,:) = Lchain(infServers,:) ./ Vchain(infServers,:);
    Tchain = repmat(Xchain,M,1) .* Vchain;
    %Uchain = Tchain .* Lchain;
    %Cchain = Nchain ./ Xchain - Z;
    
    [Q,U,R,T,C,X] = snDeaggregateChainResults(sn, Lchain, ST, STchain, Vchain, alpha, [], [], Rchain, Tchain, [], Xchain);
    
    for i=1:M
        rho(i) = sum(U(i,:)); % true utilization of each server, critical to use this
    end
    
    if it==1
        ca= zeros(M,1);
        %ca_1 = ones(M,1);
        cs_1 = ones(M,1);
        for i=1:M
            sd = sn.rates(i,:)>0;
            cs_1(i) = mean(SCV(i,sd));
        end
    else
        ca_1 = ca;
        cs_1 = cs;
    end
    
    for i=1:M
        sd = sn.rates(i,:)>0;
        switch schedid(i)
            case SchedStrategy.ID_FCFS
                if range(ST0(i,sd))>0 && (max(SCV(i,sd))>1 - Distrib.Zero || min(SCV(i,sd))<1 + Distrib.Zero) % check if non-product-form
                    ca(i) = 1;
                    cs(i) = (SCV(i,sd)*T(i,sd)')/sum(T(i,sd));
                    gamma(i) = (rho(i)^nservers(i)+rho(i))/2; % multi-server
                    % asymptotic decay rate (diffusion approximation, Kobayashi JACM)
                    eta(i) = exp(-2*(1-rho(i))/(cs(i)+ca(i)*rho(i)));
                    %eta(i) = rho(i);
                end
        end
    end
    
    for i=1:M
        sd = sn.rates(i,:)>0;
        switch schedid(i)
            case SchedStrategy.ID_FCFS
                if range(ST0(i,sd))>0 && (max(SCV(i,sd))>1 - Distrib.Zero || min(SCV(i,sd))<1 + Distrib.Zero) % check if non-product-form
                    for k=1:K
                        if sn.rates(i,k)>0
                            ST(i,k) = (1-rho(i)^8)*ST0(i,k) + rho(i)^8*(gamma(i) + rho(i)^8* (eta(i)-gamma(i)))*(nservers(i)/sum(T(i,sd)));
                        end
                    end
                end
        end
    end
    
end

runtime = toc(Tstart);
Q=abs(Q); R=abs(R); X=abs(X); U=abs(U);
X(~isfinite(X))=0; U(~isfinite(U))=0; Q(~isfinite(Q))=0; R(~isfinite(R))=0;
return
end