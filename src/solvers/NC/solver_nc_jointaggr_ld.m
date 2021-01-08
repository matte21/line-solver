tinfunction [Pr,G,runtime] = solver_nc_jointaggr_ld(sn, options)
% [PR,G,RUNTIME] = SOLVER_NC_JOINTAGGR(QN, OPTIONS)

% Copyright (c) 2012-2021, Imperial College London
% All rights reserved.

M = sn.nstations;    %number of stations
K = sn.nclasses;    %number of classes
state = sn.state;
S = sn.nservers;
NK = sn.njobs';  % initial population per class
C = sn.nchains;
PH = sn.proc;
%% initialization

% determine service times
ST = zeros(M,K);
for k = 1:K
    for i=1:M
        ST(i,k) = 1 ./ map_lambda(PH{i,k});
    end
end
ST(isnan(ST))=0;

alpha = zeros(sn.nstations,sn.nclasses);
Vchain = zeros(sn.nstations,sn.nchains);
for c=1:sn.nchains
    inchain = find(sn.chains(c,:));
    for i=1:sn.nstations
        Vchain(i,c) = sum(sn.visits{c}(i,inchain)) / sum(sn.visits{c}(sn.refstat(inchain(1)),inchain));
        for k=inchain
            alpha(i,k) = alpha(i,k) + sn.visits{c}(i,k) / sum(sn.visits{c}(i,inchain)); % isn't alpha(i,j) always zero when entering here?
        end
    end
end

Vchain(~isfinite(Vchain))=0;
alpha(~isfinite(alpha))=0;

Lchain = zeros(M,C);
STchain = zeros(M,C);

Nchain = zeros(1,C);
refstatchain = zeros(C,1);
for c=1:sn.nchains
    inchain = find(sn.chains(c,:));
    isOpenChain = any(isinf(sn.njobs(inchain)));
    for i=1:sn.nstations
        % we assume that the visits in L(i,inchain) are equal to 1
        STchain(i,c) = ST(i,inchain) * alpha(i,inchain)';
        if isOpenChain && i == sn.refstat(inchain(1)) % if this is a source ST = 1 / arrival rates
            STchain(i,c) = 1 / sumfinite(sn.rates(i,inchain)); % ignore degenerate classes with zero arrival rates
        else
            STchain(i,c) = ST(i,inchain) * alpha(i,inchain)';
        end
        Lchain(i,c) = Vchain(i,c) * ST(i,inchain) * alpha(i,inchain)';
    end
    Nchain(c) = sum(NK(inchain));
    refstatchain(c) = sn.refstat(inchain(1));
    if any((sn.refstat(inchain(1))-refstatchain(c))~=0)
        line_error(sprintf('Classes in chain %d have different reference station.',c));
    end
end
STchain(~isfinite(STchain))=0;
Lchain(~isfinite(Lchain))=0;
Tstart = tic;

[M,K]=size(STchain);

Lchain = zeros(M,K);
mu_chain = ones(M,sum(Nchain));
for i=1:M
    Lchain(i,:) = STchain(i,:) .* Vchain(i,:);
    if isinf(S(i)) % infinite server
        mu_chain(i,1:sum(Nchain)) = 1:sum(Nchain);
    else
        mu_chain(i,1:sum(Nchain)) = min(1:sum(Nchain), S(i)*ones(1,sum(Nchain)));
    end
end

G = pfqn_gmvald(Lchain, Nchain, mu_chain);
Pr = 1;
for i=1:M
    isf = sn.stationToStateful(i);
    [~,nivec] = State.toMarginal(sn, i, state{isf});
    nivec_chain = nivec * sn.chains';
    F_i = pfqn_gmvald(Lchain(i,:), nivec_chain, mu_chain(i,:));
    g0_i = pfqn_gmvald(ST(i,:).*alpha(i,:),nivec, mu_chain(i,:));
    G0_i = pfqn_gmvald(STchain(i,:),nivec_chain, mu_chain(i,:));
    Pr = Pr * F_i * (g0_i / G0_i);
end
Pr = Pr / G;

runtime = toc(Tstart);

lG = log(G);
if options.verbose > 0
    line_printf('\nNormalizing constant (NC) analysis completed. Runtime: %f seconds.\n',runtime);
end
return
end
