function [Pr,G,runtime] = solver_nc_marg(sn, options, lG)
% [PR,G,RUNTIME] = SOLVER_NC_MARG(QN, OPTIONS)

% Copyright (c) 2012-2022, Imperial College London
% All rights reserved.

if nargin == 2
    lG = NaN;
end

M = sn.nstations;    %number of stations
K = sn.nclasses;    %number of classes
state = sn.state;
S = sn.nservers;
NK = sn.njobs';  % initial population per class
C = sn.nchains;

PHr = sn.proc;

%% initialization

% determine service times
ST = zeros(M,K);
V = zeros(M,K);
for k = 1:K
    for i=1:M
        ST(i,k) = 1 ./ map_lambda(PHr{i}{k});
    end
end
ST(isnan(ST))=0;
for c=1:sn.nchains
    V = V + sn.visits{c};
end

[Lchain,STchain,~,~,Nchain] = snGetDemandsChain(sn);

Tstart = tic;

[M,K]=size(STchain);

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

for ist=1:sn.nstations
    ind = sn.stationToNode(ist);
    isf = sn.stationToStateful(ist);
    [~,nirvec,sivec,kirvec] = State.toMarginal(sn, ind, state{isf});
    if min(nirvec) < 0 % user flags that state of i should be ignored
        Pr(i) = NaN;
    else
        set_ist = setdiff(1:sn.nstations,ist);
        nivec_chain = nirvec * sn.chains';
        G_minus_i = exp(pfqn_ncld(Lchain(set_ist,:), Nchain-nivec_chain, 0*Nchain, mu(set_ist,:), options));
        F_i = 1;
        switch sn.schedid(ist)
            case SchedStrategy.ID_FCFS
                for r=1:K
                    PHr = sn.proc{ist}{r};
                    if ~isempty(PHr)
                        kir = kirvec(1,r,:); kir=kir(:)';
                        if length(kir)>1
                            line_error(mfilename,'Cannot return state probability because the product-form solution requires exponential service times at FCFS nodes.');
                        end
                        if ST(ist,r)~=max(ST(ist,:))
                            line_error(mfilename,'Cannot return state probability because the product-form solution requires identical service times at FCFS nodes.');
                        end
                    end
                end
                ci = find(sivec);
                if ~isempty(ci)
                    F_i = F_i * prod(exp(nirvec(1,:).*log(V(ist,r))))./prod(mu(ist,1:sum(kirvec(:))));
                else
                    F_i = 1;
                end
            case SchedStrategy.ID_SIRO
                for r=1:K
                    PHr = sn.proc{ist}{r};
                    if ~isempty(PHr)
                        kir = kirvec(1,r,:); kir=kir(:)';
                        if length(kir)>1
                            line_error(mfilename,'Cannot return state probability because the product-form solution requires exponential service times at RAND nodes.');
                        end
                        if ST(ist,r)~=max(ST(ist,:))
                            line_error(mfilename,'Cannot return state probability because the product-form solution requires identical service times at RAND nodes.');
                        end
                    end
                end
                ci = find(sivec);
                if ~isempty(ci)
                    F_i = (nirvec(ci)/sum(nirvec)) * exp(pfqn_ncldld(ST(ist,:).*V(ist,:), nirvec, 0*nirvec, mu(ist,:), options));
                else
                    F_i = 1;
                end
            case SchedStrategy.ID_PS
                for r=1:K
                    PHr = sn.proc{ist}{r};
                    if ~isempty(PHr)
                        kir = kirvec(1,r,:); kir=kir(:)';
                        Ar = map_pie(PHr)*inv(-PHr{1});
                        F_i = F_i * prod(exp(kir.*log(V(ist,r)*Ar)))./prod(factorial(kir));
                    end
                end
                F_i = F_i * factorial(sum(kirvec(:)))./prod(mu(ist,1:sum(kirvec(:))));
            case SchedStrategy.ID_INF
                for r=1:K
                    PHr = sn.proc{ist}{r};
                    if ~isempty(PHr)
                        kir = kirvec(1,r,:); kir=kir(:)';
                        Ar = map_pie(PHr)*inv(-PHr{1});
                        F_i = F_i * prod(exp(kir.*log(V(ist,r)*Ar)))./prod(factorial(kir));
                    end
                end
        end
        Pr(ist) =  F_i * G_minus_i / G;
    end
end

runtime = toc(Tstart);
Pr(isnan(Pr))=0;
lG = log(G);
if options.verbose
    line_printf('\nNormalizing constant (NC) analysis completed. Runtime: %f seconds.\n',runtime);
end
return
end
