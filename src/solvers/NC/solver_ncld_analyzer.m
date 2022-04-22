function [Q,U,R,T,C,X,lG,runtime] = solver_ncld_analyzer(sn, options)
% [Q,U,R,T,C,X,LG,RUNTIME] = SOLVER_NCLD_ANALYZER(QN, OPTIONS)

% Copyright (c) 2012-2022, Imperial College London
% All rights reserved.
M = sn.nstations;    %number of stations
K = sn.nclasses;
nservers = sn.nservers;

if nservers(isfinite(nservers))>1
    line_error(mfilename,'The load-dependent solver does not support multi-server stations yet. Specify multi-server stations via limited load-dependence.');
end

if ~isempty(sn.cdscaling) && strcmpi(options.method, 'exact')
    line_error(mfilename,'Exact class-dependent solver not yet available in NC.');
end

NK = sn.njobs';  % initial population per class

if isinf(max(NK))
    line_error(mfilename,'The load-dependent solver does not support open classes yet.');
end

schedid = sn.schedid;
%chains = sn.chains;
C = sn.nchains;
SCV = sn.scv;
gamma = zeros(M,1);
V = cellsum(sn.visits);
ST = 1 ./ sn.rates;
ST(isnan(ST))=0;
ST0=ST;
lldscaling = sn.lldscaling;
Nt = sum(NK(isfinite(NK)));
if isempty(lldscaling)
    lldscaling = ones(M,Nt);
end

[~,~,Vchain,alpha] = snGetDemandsChain(sn);

eta_1 = zeros(1,M);
eta = ones(1,M);
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
        inchain = sn.inchain{c};
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
    lG = pfqn_ncld(Lms, Nchain, 0*Nchain, mu, options);
    lG = real(lG);
    Xchain=[];
    Qchain=[];

    if isempty(Xchain)
        for r=1:C
            %r
            Nchain_r =oner(Nchain,r);
            [lGr(r)] = pfqn_ncld(Lms,Nchain_r,0*Nchain,mu,options);
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
                            [lGhat_fnci(r)] = pfqn_ncld([Lms;Lms(i,:)],Nchain_r, 0*Nchain, [muhati;muhati_f], options);
                            [lGhatir(r)] = pfqn_ncld(Lms,Nchain_r, 0*Nchain, muhati, options);
                            [lGr_i(r)] = pfqn_ncld(Lms_i,Nchain_r, 0*Nchain, mu_i, options);
                            [lGhati(r)] = pfqn_ncld(Lms,Nchain_r, 0*Nchain, muhati, options);
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

    [Q,U,R,T,C,X] = snDeaggregateChainResults(sn, Lchain, ST, STchain, Vchain, alpha, [], [], Rchain, Tchain, [], Xchain);

    [ST,gamma,~,~,~,~,eta] = handlerHighVar(options.config.highvar,sn,ST0,V,SCV,X,U,gamma,nservers);
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