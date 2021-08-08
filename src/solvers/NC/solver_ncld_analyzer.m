function [Q,U,R,T,C,X,lG,runtime] = solver_ncld_analyzer(sn, options)
% [Q,U,R,T,C,X,LG,RUNTIME] = SOLVER_NCLD_ANALYZER(QN, OPTIONS)

% Copyright (c) 2012-2021, Imperial College London
% All rights reserved.
M = sn.nstations;    %number of stations
nservers = sn.nservers;
if nservers(isfinite(nservers))>1
    error('The load-dependent solver does not support multi-server stations. Specify multi-server stations via limited load-dependence.');
end
NK = sn.njobs';  % initial population per class
schedid = sn.schedid;
%chains = sn.chains;
C = sn.nchains;
SCV = sn.scv;
ST = 1 ./ sn.rates;
ST(isnan(ST))=0;
ST0=ST;
lldscaling = sn.lldscaling;

alpha = zeros(sn.nstations,sn.nclasses);
Vchain = zeros(sn.nstations,sn.nchains);
for c=1:sn.nchains
    inchain = find(sn.chains(c,:));
    for i=1:sn.nstations
        Vchain(i,c) = sum(sn.visits{c}(i,inchain)) / sum(sn.visits{c}(sn.refstat(inchain(1)),inchain));
        for k=inchain
            alpha(i,k) = alpha(i,k) + sn.visits{c}(i,k) / sum(sn.visits{c}(i,inchain));
        end
    end
end
Vchain(~isfinite(Vchain))=0;
alpha(~isfinite(alpha))=0;
alpha(alpha<1e-12)=0;
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
    Nchain = zeros(1,C);
    refstatchain = zeros(C,1);
    for c=1:C
        inchain = find(sn.chains(c,:));
        isOpenChain = any(isinf(sn.njobs(inchain)));
        for i=1:M
            % we assume that the visits in L(i,inchain) are equal to 1
            Lchain(i,c) = Vchain(i,c) * ST(i,inchain) * alpha(i,inchain)';
            STchain(i,c) = ST(i,inchain) * alpha(i,inchain)';
            if isOpenChain && i == sn.refstat(inchain(1)) % if this is a source ST = 1 / arrival rates
                STchain(i,c) = sumfinite(ST(i,inchain)); % ignore degenerate classes with zero arrival rates
            else
                STchain(i,c) = ST(i,inchain) * alpha(i,inchain)';
            end
            SCVchain(i,c) = SCV(i,inchain) * alpha(i,inchain)';
        end
        Nchain(c) = sum(NK(inchain));
        refstatchain(c) = sn.refstat(inchain(1));
        if any((sn.refstat(inchain(1))-refstatchain(c))~=0)
            line_error(mfilename,sprintf('Classes in chain %d have different reference station.',c));
        end
    end
    STchain(~isfinite(STchain))=0;
    Lchain(~isfinite(Lchain))=0;
    Tstart = tic;
    Nt = sum(Nchain(isfinite(Nchain)));
    
    Lms = zeros(M,C);
    mu = zeros(M,Nt);
    infServers = [];
    Z = zeros(M,C);
    for i=1:M
        if isinf(nservers(i)) % infinite server
            %mu_chain(i,1:sum(Nchain)) = 1:sum(Nchain);
            infServers(end+1) = i;
            Lms(i,:) = Lchain(i,:);
            Z(i,:) = Lchain(i,:);
            mu(i,1:Nt) = 1:Nt;
        else
            if strcmpi(options.method,'exact') && nservers(i)>1
                %options.method = 'default';
                line_warning(mfilename,sprintf('%s does not support exact multiserver yet. Switching to approximate method.', 'SolverNC'));
            end
            Lms(i,:) = Lchain(i,:);
            mu(i,1:Nt) = lldscaling(i,1:Nt);
        end
    end
    Qchain = zeros(M,C);
    % step 1
    switch options.method
        case {'default','exact'}
            [~,lG]=pfqn_gmvald(Lms, Nchain, mu, options);
        case 'rd'
            %if debug
            %    [~,lG_ex]=pfqn_gmvald(Lms, Nchain, mu, options)
            %end
            [lG]=pfqn_rd(Lms, Nchain, 0*Nchain, mu, options);
        case {'nrp','nr.probit'}
            [lG]=pfqn_nrp(Lms, Nchain, 0*Nchain, mu, options);
        case {'nrl','nr.logit'}
            [lG]=pfqn_nrl(Lms, Nchain, 0*Nchain, mu, options);
    end
    lG = real(lG);
    Xchain=[];
    Qchain=[];
    
    if isempty(Xchain)
        for r=1:C
            %r
            Nchain_r =oner(Nchain,r);
            switch options.method
                case {'default','exact'}
                    [~,lGr(r)] = pfqn_gmvald(Lms,Nchain_r, mu, options);
                case 'rd'
                    %if debug
                    %    [~,lGr_ex(r)] = pfqn_gmvald(Lms,Nchain_r, mu, options)
                    %end
                    [lGr(r)] = pfqn_rd(Lms,Nchain_r,0*Nchain,mu,options);
                case {'nrp','nr.probit'}
                    [lGr(r)] = pfqn_nrp(Lms,Nchain_r,0*Nchain,mu,options);
                case {'nrl','nr.logit'}
                    [lGr(r)] = pfqn_nrl(Lms,Nchain_r,0*Nchain,mu,options);
            end
            lGr = real(lGr);
            Xchain(r) = exp(lGr(r) - lG);
            for i=1:M
                Qchain(i,r)=0;
            end
            CQchain_r = zeros(M,1);
            for i=1:M
                %i
                Lms_i = Lms; Lms_i(i,:) = [];
                mu_i = mu; mu_i(i,:) = [];
                muhati = mu; muhati = pfqn_mushift(mu,i); %#ok<NASGU>
                [muhati_f,c] = pfqn_fnc(muhati(i,:));
                if Lchain(i,r)>0
                    if isinf(nservers(i)) % infinite server
                        Qchain(i,r) = real(Lchain(i,r) * Xchain(r));
                    else
                        if  i==M && sum(isfinite(nservers))==1 % normalize queue-lengths to Nchain(r)
                            Qchain(i,r) = max(0,real(Nchain(r) - sum(Lchain(isinf(nservers),r)) * Xchain(r)) - sum(Qchain(setdiff(1:(M-1),find(isinf(nservers))),r)));
                        else
                            switch options.method
                                case {'default','exact'}
                                    [~,lGhat_fnci(r)] = pfqn_gmvald([Lms;Lms(i,:)],Nchain_r, [muhati;muhati_f], options);
                                    [~,lGhatir(r)] = pfqn_gmvald(Lms,Nchain_r, muhati, options);
                                    [~,lGr_i(r)] = pfqn_gmvald(Lms_i,Nchain_r, mu_i, options);
                                    [~,lGhati(r)] = pfqn_gmvald(Lms,Nchain_r, muhati, options);
                                case 'rd'
                                    %if debug
                                    %    [~,lGhat_fnci_ex(r)] = pfqn_gmvald([Lms;Lms(i,:)],Nchain_r, [muhati;muhati_f], options)
                                    %end
                                    [lGhat_fnci(r)] = pfqn_rd([Lms;Lms(i,:)], Nchain_r, 0*Nchain, [muhati;muhati_f], options);
                                    %if debug
                                    %    [~,lGhatir_ex(r)] = pfqn_gmvald(Lms,Nchain_r, muhati, options)
                                    %end
                                    [lGhatir(r)] = pfqn_rd(Lms,Nchain_r, 0*Nchain, muhati, options);
                                    %if debug
                                    %    [~,lGr_i_ex(r)] = pfqn_gmvald(Lms_i,Nchain_r, mu_i, options)
                                    %end
                                    [lGr_i(r)] = pfqn_rd(Lms_i,Nchain_r, 0*Nchain, mu_i, options);
                                    %if debug
                                    %    [~,lGhati_ex(r)] = pfqn_gmvald(Lms,Nchain_r, muhati, options)
                                    %end
                                    [lGhati(r)] = pfqn_rd(Lms,Nchain_r, 0*Nchain, muhati, options);
                                case {'nrp','nr.probit'}
                                    [lGhat_fnci(r)] = pfqn_nrp([Lms;Lms(i,:)],Nchain_r, 0*Nchain, [muhati;muhati_f], options);
                                    [lGhatir(r)] = pfqn_nrp(Lms,Nchain_r, 0*Nchain, muhati, options);
                                    [lGr_i(r)] = pfqn_nrp(Lms_i,Nchain_r, 0*Nchain, mu_i, options);
                                    [lGhati(r)] = pfqn_nrp(Lms,Nchain_r, 0*Nchain, muhati, options);
                                case {'nrl','nr.logit'}
                                    [lGhat_fnci(r)] = pfqn_nrl([Lms;Lms(i,:)],Nchain_r, 0*Nchain, [muhati;muhati_f], options);
                                    [lGhatir(r)] = pfqn_nrl(Lms,Nchain_r, 0*Nchain, muhati, options);
                                    [lGr_i(r)] = pfqn_nrl(Lms_i,Nchain_r, 0*Nchain, mu_i, options);
                                    [lGhati(r)] = pfqn_nrl(Lms,Nchain_r, 0*Nchain, muhati, options);
                            end
                            dlGa = real(lGhat_fnci(r)) - real(lGhatir(r));
                            dlG_i = real(lGr_i(r)) - real(lGhatir(r));
                            CQchain(i) = (exp(dlGa) - 1) + c*(exp(dlG_i)-1); % conditional qlen
                            ldDemand(i,r) = log(Lms(i,r)) + real(lGhati(r)) - log(mu(i,1)) - real(lGr(r));
                            Qchain(i,r) = exp(ldDemand(i,r)) * Xchain(r) * (1+CQchain(i)); % conditional MVA formula
                        end
                    end
                end
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
    Uchain = Tchain .* Lchain;
    Cchain = Nchain ./ Xchain - Z;
    
    Xchain=real(Xchain);
    Uchain=real(Uchain);
    Qchain=real(Qchain);
    Rchain=real(Rchain);
    
    Xchain(~isfinite(Xchain))=0;
    Uchain(~isfinite(Uchain))=0;
    Qchain(~isfinite(Qchain))=0;
    Rchain(~isfinite(Rchain))=0;
    
    Xchain(Nchain==0)=0;
    Uchain(:,Nchain==0)=0;
    Qchain(:,Nchain==0)=0;
    Rchain(:,Nchain==0)=0;
    Tchain(:,Nchain==0)=0;
    
    for c=1:sn.nchains
        inchain = find(sn.chains(c,:));
        for k=inchain(:)'
            X(k) = Xchain(c) * alpha(sn.refstat(k),k);
            for i=1:sn.nstations
                if isinf(nservers(i))
                    U(i,k) = ST(i,k) * (Xchain(c) * Vchain(i,c) / Vchain(sn.refstat(k),c)) * alpha(i,k);
                else
                    U(i,k) = ST(i,k) * (Xchain(c) * Vchain(i,c) / Vchain(sn.refstat(k),c)) * alpha(i,k) / nservers(i);
                end
                if Lchain(i,c) > 0
                    Q(i,k) = Rchain(i,c) * ST(i,k) / STchain(i,c) * Xchain(c) * Vchain(i,c) / Vchain(sn.refstat(k),c) * alpha(i,k);
                    T(i,k) = Tchain(i,c) * alpha(i,k);
                    R(i,k) = Q(i,k) / T(i,k);
                    % R(i,k) = Rchain(i,c) * ST(i,k) / STchain(i,c) * alpha(i,k) / sum(alpha(sn.refstat(k),inchain)');
                else
                    T(i,k) = 0;
                    R(i,k) = 0;
                    Q(i,k) = 0;
                end
            end
            C(k) = sn.njobs(k) / X(k);
        end
    end
    
    for i=1:M
        rho(i) = sum(U(i,:)); % true utilization of each server, critical to use this
    end
    
    if it==1
        ca= zeros(M,1);
        ca_1 = ones(M,1);
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
                    %                    if rho(i) <= 1
                    %                     else
                    %                         ca(i) = 0;
                    %                         for j=1:M
                    %                             for r=1:K
                    %                                 if ST0(j,r)>0
                    %                                     for s=1:K
                    %                                         if ST0(i,s)>0
                    %                                             pji_rs = sn.rt((j-1)*sn.nclasses + r, (i-1)*sn.nclasses + s);
                    %                                             ca(i) = ca(i) + (T(j,r)*pji_rs/sum(T(i,sd)))*(1 - pji_rs + pji_rs*((1-rho(j)^2)*ca_1(j) + rho(j)^2*cs_1(j)));
                    %                                         end
                    %                                     end
                    %                                 end
                    %                             end
                    %                         end
                    %                     end
                    ca(i) = 1;
                    cs(i) = (SCV(i,sd)*T(i,sd)')/sum(T(i,sd));
                    gamma(i) = (rho(i)^nservers(i)+rho(i))/2; % multi-server
                    % asymptotic decay rate (diffusion approximation, Kobayashi JACM)
                    eta(i) = exp(-2*(1-rho(i))/(cs(i)+ca(i)*rho(i)));
                    %[~,eta(i)]=qsys_gig1_approx_klb(sum(T(i,sd))/nservers(i),rho(i) / (sum(T(i,sd))/nservers(i)),ca(i),cs(i));
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
                            ST(i,k) = (1-rho(i)^4)*ST0(i,k) + rho(i)^4*((1-rho(i)^4) * gamma(i)*nservers(i)/sum(T(i,sd)) +  rho(i)^4* eta(i)*nservers(i)/sum(T(i,sd)) );
                        end
                    end
                end
        end
    end
    
end

runtime = toc(Tstart);
Q=abs(Q); R=abs(R); X=abs(X); U=abs(U);
for i=1:M
    U(i,:) = U(i,:) / max(lldscaling(i,:));
    if sum(U(i,:)) > 1
        U(i,:) = U(i,:) / sum(U(i,:));
    end
end

X(~isfinite(X))=0; U(~isfinite(U))=0; Q(~isfinite(Q))=0; R(~isfinite(R))=0;
return
end