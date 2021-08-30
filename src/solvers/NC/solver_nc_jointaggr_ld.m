function [Pr,G,runtime] = solver_nc_jointaggr_ld(sn, options)
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
        ST(i,k) = 1 ./ map_lambda(PH{i}{k});
    end
end
ST(isnan(ST))=0;

[Lchain, STchain, Vchain, alpha, Nchain] = snGetDemandsChain(sn);

Tstart = tic;

[M,K]=size(STchain);

Lchain = zeros(M,K);
mu_chain = ones(M,sum(Nchain));
for i=1:M
    if isinf(S(i)) % infinite server
        mu_chain(i,1:sum(Nchain)) = 1:sum(Nchain);
    else
        mu_chain(i,1:sum(Nchain)) = min(1:sum(Nchain), S(i)*ones(1,sum(Nchain)));
    end
end

G = exp(pfqn_ncld(Lchain, Nchain, 0*Nchain, mu_chain));
Pr = 1;
for i=1:M
    isf = sn.stationToStateful(i);
    [~,nivec] = State.toMarginal(sn, i, state{isf});
    nivec_chain = nivec * sn.chains';
    F_i = exp(pfqn_ncld(Lchain(i,:), nivec_chain, 0*nivec_chain, mu_chain(i,:)));
    g0_i = exp(pfqn_ncld(ST(i,:).*alpha(i,:), nivec, 0*nivec, mu_chain(i,:)));
    G0_i = exp(pfqn_ncld(STchain(i,:),nivec_chain, 0*nivec_chain, mu_chain(i,:)));
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
