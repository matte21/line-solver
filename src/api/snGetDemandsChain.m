function [Dchain,STchain,Vchain,alpha] = snGetDemandsChain(sn)

M = sn.nstations;    %number of stations
K = sn.nclasses;    %number of classes
C = sn.nchains;

PH = sn.proc;

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
            alpha(i,k) = alpha(i,k) + sn.visits{c}(i,k) / sum(sn.visits{c}(i,inchain));
        end
    end
end
Vchain(~isfinite(Vchain))=0;
alpha(~isfinite(alpha))=0;

Dchain = zeros(M,C);
STchain = zeros(M,C);

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
        Dchain(i,c) = Vchain(i,c) * STchain(i,c);
    end
    refstatchain(c) = sn.refstat(inchain(1));
    if any((sn.refstat(inchain(1))-refstatchain(c))~=0)
        line_error(sprintf('Classes in chain %d have different reference station.',c));
    end
end
Dchain(~isfinite(Dchain))=0;
end