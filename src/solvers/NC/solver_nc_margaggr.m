function [Pr,G,runtime] = solver_nc_margaggr(sn, options, lG)
% [PR,G,RUNTIME] = SOLVER_NC_MARGAGGR(QN, OPTIONS)

% Copyright (c) 2012-2021, Imperial College London
% All rights reserved.

M = sn.nstations;    %number of stations
K = sn.nclasses;    %number of classes
state = sn.state;
S = sn.nservers;
NK = sn.njobs';  % initial population per class
C = sn.nchains;

PH = sn.proc;

if nargin == 2
    lG = NaN;
end

%% initialization

% determine service times
ST = zeros(M,K);
for k = 1:K
    for i=1:M
        ST(i,k) = 1 ./ map_lambda(PH{i}{k});
    end
end
ST(isnan(ST))=0;

[Lchain,STchain,Vchain,~,Nchain] = snGetDemandsChain(sn);
V = zeros(sn.nstations,sn.nclasses);
for c=1:sn.nchains
    inchain = find(sn.chains(c,:));
    for i=1:sn.nstations
        for k=inchain
            V(i,k) = sn.visits{c}(i,k);
        end
    end
end

Tstart = tic;

[M,~]=size(STchain);

mu = ones(M,sum(Nchain));
for i=1:M
    if isinf(S(i)) % infinite server
        mu(i,1:sum(Nchain)) = 1:sum(Nchain);
    else
        mu(i,1:sum(Nchain)) = min(1:sum(Nchain), S(i)*ones(1,sum(Nchain)));
    end
end

if isnan(lG)
    G = exp(pfqn_ncld(Lchain, Nchain, 0*Nchain, mu));
else
    G = exp(lG);
end

%Pr = zeros(sn.nstations,1);
for ist=1:sn.nstations
    ind = sn.stationToNode(ist);
    isf = sn.stationToStateful(ist);
    [~,nivec] = State.toMarginal(sn, ind, state{isf});
    if min(nivec) < 0 % user flags that state of i should be ignored
        Pr(i) = NaN;
    else
        set_ist = setdiff(1:sn.nstations,ist);
        nivec_chain = nivec * sn.chains';
        G_minus_i = exp(pfqn_ncld(Lchain(set_ist,:), Nchain-nivec_chain, 0*Nchain, mu(set_ist,:), options));
        F_i = exp(pfqn_ncld(ST(ist,:).*V(ist,:), nivec, 0*nivec, mu(ist,:), options));
        Pr(ist) =  F_i * G_minus_i / G;
    end
end

% Pr = 1;
% for i=1:M
%     isf = sn.stationToStateful(i);
%     [~,nivec] = State.toMarginal(sn, i, state{isf});
%     nivec_chain = nivec * sn.chains';
%     F_i = exp(pfqn_ncld(Lchain(i,:), nivec_chain, mu_chain(i,:));
%     G_minus_i = exp(pfqn_ncld(Lchain(setdiff(1:M,i),:), Nchain-nivec_chain, mu_chain(setdiff(1:M,i),:));
%     g0_i = exp(pfqn_ncld(ST(i,:).*alpha(i,:),nivec, mu_chain(i,:));
%     G0_i = exp(pfqn_ncld(STchain(i,:),nivec_chain, mu_chain(i,:));
%     Pr = F_i * G_minus_i / G * (g0_i / G0_i);
% end
%

runtime = toc(Tstart);
Pr(isnan(Pr))=0;
lG = log(G);
if options.verbose > 0
    line_printf('Normalizing constant (NC) analysis completed. Runtime: %f seconds.\n',runtime);
end
return
end