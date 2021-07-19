function [Pr,G,runtime] = solver_nc_jointaggr(sn, options)
% [PR,G,RUNTIME] = SOLVER_NC_JOINTAGGR(QN, OPTIONS)

% Copyright (c) 2012-2021, Imperial College London
% All rights reserved.

method = options.method;
M = sn.nstations;    %number of stations
nservers = sn.nservers;
NK = sn.njobs';  % initial population per class
schedid = sn.schedid;
%chains = sn.chains;
SCV = sn.scv;
ST = 1 ./ sn.rates;
ST(isnan(ST))=0;
ST0=ST;

alpha = zeros(sn.nstations,sn.nclasses);
Vchain = zeros(sn.nstations,sn.nchains);
V = zeros(sn.nstations,sn.nclasses);
for c=1:sn.nchains
    inchain = find(sn.chains(c,:));
    for i=1:sn.nstations
        Vchain(i,c) = sum(sn.visits{c}(i,inchain)) / sum(sn.visits{c}(sn.refstat(inchain(1)),inchain));
        for k=inchain
            V(i,k) = sn.visits{c}(i,k);
            alpha(i,k) = alpha(i,k) + sn.visits{c}(i,k) / sum(sn.visits{c}(i,inchain));
        end
    end
end
Vchain(~isfinite(Vchain))=0;
alpha(~isfinite(alpha))=0;
alpha(alpha<1e-12)=0;
eta_1 = zeros(1,M);
eta = ones(1,M);
ca = ones(1,M);

if ~any(schedid==SchedStrategy.ID_FCFS) options.iter_max=1; end

it = 0;
while max(abs(1-eta./eta_1)) > options.iter_tol && it <= options.iter_max
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
    if it==1
        Lchain0 = Lchain;
        STchain0 = STchain;
    end
    Tstart = tic;
    Nt = sum(Nchain(isfinite(Nchain)));
    
    Lcorr = zeros(M,C);
    Z = zeros(M,C);
    Zcorr = zeros(M,C);
    infServers = [];
    for i=1:M
        if isinf(nservers(i)) % infinite server
            %mu_chain(i,1:sum(Nchain)) = 1:sum(Nchain);
            infServers(end+1) = i;
            Lcorr(i,:) = 0;
            Z(i,:) = Lchain(i,:);
            Zcorr(i,:) = 0;
        else
            %if strcmpi(options.method,'exact') && nservers(i)>1
            %    options.method = 'default';
            %    line_warning(mfilename,'%s does not support exact multiserver yet. Switching to approximate method.', mfilename);
            %end
            Lcorr(i,:) = Lchain(i,:) / nservers(i);
            Z(i,:) = 0;
            Zcorr(i,:) = Lchain(i,:) * (nservers(i)-1)/nservers(i);
        end
    end
    Qchain = zeros(M,C);
    
    % step 1
    lG = pfqn_nc(Lcorr,Nchain,sum(Z,1)+sum(Zcorr,1), options);
    
    for r=1:C
        lGr(r) = pfqn_nc(Lcorr,oner(Nchain,r),sum(Z,1)+sum(Zcorr,1), options);
        Xchain(r) = exp(lGr(r) - lG);
        for i=1:M
            if Lchain(i,r)>0
                if isinf(nservers(i)) % infinite server
                    Qchain(i,r) = Lchain(i,r) * Xchain(r);
                else
                    lGar(i,r) = pfqn_nc([Lcorr(setdiff(1:size(Lcorr,1),i),:),zeros(size(Lcorr,1)-1,1); Lcorr(i,:),1], [oner(Nchain,r),1], [sum(Z,1)+sum(Zcorr,1),0], options);
                    Qchain(i,r) = Zcorr(i,r) * Xchain(r) + Lcorr(i,r) * exp(lGar(i,r) - lG);
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
    
    ca_1 = ca;
    for i=1:M
        sd = ST0(i,:)>0;
        eta(i) = sum(U(i,:));
        switch schedid(i)
            case SchedStrategy.ID_FCFS
                %if range(ST0(i,sd))>0 && (max(SCV(i,sd))>1 - Distrib.Zero || min(SCV(i,sd))<1 + Distrib.Zero) % check if non-product-form
                rho(i) = sum(U(i,:)); % true utilization of each server
                ca(i) = 0;
                for j=1:M
                    for r=1:K
                        if ST0(j,r)>0
                            for s=1:K
                                if ST0(i,s)>0 && ST0(j,r)>0
                                    pji_rs = sn.rt((j-1)*sn.nclasses + r, (i-1)*sn.nclasses + s);
                                    ca(i) = ca(i) + (T(j,r)*pji_rs/sum(T(i,sd)))*(1 - pji_rs + pji_rs*((1-rho(j)^2)*ca_1(j) + rho(j)^2*SCV(j,r)));
                                end
                            end
                        end
                    end
                end
                
                cs(i) = ((SCV(i,sd)*T(i,sd)')/sum(T(i,sd)));
                %cs(i)=1;
                
                % asymptotic decay rate (diffusion approximation, Kobayashi JACM)
                eta(i) = exp(-2*(1-rho(i))/(cs(i)+ca(i)*rho(i)));
                
                %MAPa = APH.fitMeanAndSCV(sum(T(i,sd)),ca(i)).getRepresentation;
                %MAPs = APH.fitMeanAndSCV(((ST(i,sd)*T(i,sd)')/sum(T(i,sd))),cs(i)).getRepresentation;
                %[~,~,~,~,~,eta(i)] = qbd_mapmap1(MAPa, MAPs, rho(i))
        end
    end
    
    for i=1:M
        sd = ST0(i,:)>0;
        switch schedid(i)
            case SchedStrategy.ID_FCFS
                %if range(ST0(i,sd))>0 && (max(SCV(i,sd))>1 - Distrib.Zero || min(SCV(i,sd))<1 + Distrib.Zero) % check if non-product-form
                for k=1:K
                    if ST0(i,k)>0
                        ST(i,k) = (1-rho(i)^2)*ST0(i,k) + rho(i)^2 * eta(i)*nservers(i)/sum(T(i,sd));
                    end
                end
                % end
            otherwise
                for k=1:K
                    ST(i,k) = ST0(i,k);
                end
        end
    end
end

C = sn.nchains;
Lchain = zeros(M,C);
mu = ones(M,sum(Nchain));
for i=1:M
    Lchain(i,:) = STchain(i,:) .* Vchain(i,:);
    if isinf(nservers(i)) % infinite server
        mu(i,1:sum(Nchain)) = 1:sum(Nchain);
    else
        mu(i,1:sum(Nchain)) = min(1:sum(Nchain), nservers(i)*ones(1,sum(Nchain)));
    end
end

state = sn.state;
G = exp(lG);

if strcmpi(method,'exact')
    G = pfqn_gmvald(Lchain, Nchain, mu);
end
Pr = 1;
for ist=1:M
    isf = sn.stationToStateful(ist);
    [~,nivec] = State.toMarginal(sn, ist, state{isf});
    nivec = unique(nivec,'rows');
    nivec_chain = nivec * sn.chains';
    if any(nivec_chain>0)
        % note that these terms have just one station so fast to compute
        %F_i = pfqn_gmvald(Lchain(i,:), nivec_chain, mu(i,:));
        %g0_i = pfqn_gmvald(ST(i,:).*alpha(i,:),nivec, mu(i,:));
        %G0_i = pfqn_gmvald(STchain(i,:),nivec_chain, mu(i,:));
        %Pr = Pr * g0_i * (F_i / G0_i);
        F_i = pfqn_gmvald(ST(ist,:).*V(ist,:), nivec, mu(ist,:), options);
        Pr = Pr * F_i ;
    end
end
Pr = Pr / G;

runtime = toc(Tstart);
return
end
