function [Pr,G,runtime] = solver_nc_jointaggr(sn, options)
% [PR,G,RUNTIME] = SOLVER_NC_JOINTAGGR(QN, OPTIONS)

% Copyright (c) 2012-2022, Imperial College London
% All rights reserved.

Tstart = tic;

V = cellsum(sn.visits);
M = sn.nstations;    %number of stations
C = sn.nchains;
Nchain = zeros(1,C);

for c=1:C
    inchain = sn.inchain{c};
    Nchain(c) = sum(sn.njobs(inchain));
end

% transform everything into a LD model
nservers = sn.nservers;
mu = ones(M,sum(Nchain));
for i=1:M
    if isinf(nservers(i)) % infinite server
        mu(i,1:sum(Nchain)) = 1:sum(Nchain);
    else
        mu(i,1:sum(Nchain)) = min(1:sum(Nchain), nservers(i)*ones(1,sum(Nchain)));
    end
end
state = sn.state;

switch options.method
    case 'exact'
        Tstart = tic;
        [Lchain,~,~,~,Nchain] = snGetDemandsChain(sn);
        G = exp(pfqn_ncld(Lchain, Nchain, 0*Nchain, mu));
        ST = 1 ./ sn.rates;
        ST(isnan(ST))=0;
    otherwise
        % unclear if this is correct as it doesn't consider the
        % transformation to ld model
        [~,~,~,~,~,~,lG,ST] = solver_nc(sn, options);
        G = exp(lG);
end

Tstart = tic;
Pr = 1;
for ist=1:M
    isf = sn.stationToStateful(ist);
    [~,nivec] = State.toMarginal(sn, ist, state{isf});
    nivec = unique(nivec,'rows');
    nivec_chain = nivec * sn.chains';
    if any(nivec_chain>0)
        % note that these terms have just one station so fast to compute
        %F_i = exp(pfqn_ncld(Lchain(i,:), nivec_chain, mu(i,:));
        %g0_i = exp(pfqn_ncld(ST(i,:).*alpha(i,:),nivec, mu(i,:));
        %G0_i = exp(pfqn_ncld(STchain(i,:),nivec_chain, mu(i,:));
        %Pr = Pr * g0_i * (F_i / G0_i);
        F_i = exp(pfqn_ncld(ST(ist,:).*V(ist,:), nivec, 0*nivec, mu(ist,:), options));
        Pr = Pr * F_i ;
    end
end
Pr = Pr / G;

runtime = toc(Tstart);
return
end

