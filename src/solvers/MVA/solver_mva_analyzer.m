function [Q,U,R,T,C,X,lG,runtime] = solver_mva_analyzer(sn, options)
% [Q,U,R,T,C,X,LG,RUNTIME] = SOLVER_MVA_ANALYZER(QN, OPTIONS)

% Copyright (c) 2012-2021, Imperial College London
% All rights reserved.

M = sn.nstations;    %number of stations
S = sn.nservers;
NK = sn.njobs';  % initial population per class
C = sn.nchains;
SCV = sn.scv;

%% initialization

% determine service times
ST = 1./sn.rates;
ST(isnan(sn.rates))=0;
SCV(isnan(SCV))=0;

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

Lchain = zeros(M,C);
STchain = zeros(M,C);

SCVchain = zeros(M,C);
Nchain = zeros(1,C);
refstatchain = zeros(C,1);
for c=1:sn.nchains
    inchain = find(sn.chains(c,:)); %classes in chain
    isOpenChain = any(isinf(sn.njobs(inchain)));
    for i=1:sn.nstations
        % we assume that the visits in L(i,inchain) are equal to 1
        Lchain(i,c) = Vchain(i,c) * ST(i,inchain) * alpha(i,inchain)';
        STchain(i,c) = ST(i,inchain) * alpha(i,inchain)';
        if isOpenChain && i == sn.refstat(inchain(1)) % if this is a source ST = 1 / arrival rates
            STchain(i,c) = 1 / sumfinite(sn.rates(i,inchain)); % ignore degenerate classes with zero arrival rates
        else
            STchain(i,c) = ST(i,inchain) * alpha(i,inchain)';
        end
        % renormalize to ignore NaN
        SCVchain(i,c) = SCV(i,inchain) * alpha(i,inchain)' / sum(alpha(i,inchain(isfinite(SCV(i,inchain))))');
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

switch options.method
    case {'exact','mva'}
        if all(isfinite(Nchain)) % if closed            
            [~,~,Rchain,Tchain,~, Xchain, lG] = solver_mva(STchain, Vchain, Nchain, S, options, sn.schedid, refstatchain);
        elseif any(isfinite(Nchain)) % if mixed
            [~,~,Rchain,Tchain,~, Xchain, lG] = solver_mva(STchain, Vchain, Nchain, S, options, sn.schedid, refstatchain);
        else % if open same as running amva
            [~,~,Rchain,Tchain,~, Xchain, lG] = solver_mva(STchain, Vchain, Nchain, S, options, sn.schedid, refstatchain);
        end
    case {'default','amva'}
        [~,Uchain,Rchain,Tchain,~, Xchain] = solver_amva(STchain, Vchain, Nchain, S, SCVchain, options, sn.schedid, sn.schedparam, refstatchain);
        lG = - log(prod(1-sum(Uchain,2))); % normalizing constant approximation
    otherwise
        line_error(mfilename,'Unsupported SolverMVA method.');
end

for c=1:sn.nchains
    inchain = find(sn.chains(c,:));
    for k=inchain(:)'
        X(k) = Xchain(c) * alpha(sn.refstat(k),k);
        for i=1:sn.nstations
            if isinf(S(i))
                U(i,k) = ST(i,k) * (Xchain(c) * Vchain(i,c) / Vchain(sn.refstat(k),c)) * alpha(i,k);
            else
                U(i,k) = ST(i,k) * (Xchain(c) * Vchain(i,c) / Vchain(sn.refstat(k),c)) * alpha(i,k) / S(i);
            end
            if Lchain(i,c) > 0
                Q(i,k) = Rchain(i,c) * ST(i,k) / STchain(i,c) * Xchain(c) * Vchain(i,c) / Vchain(sn.refstat(k),c) * alpha(i,k);
                T(i,k) = Tchain(i,c) * alpha(i,k);
                R(i,k) = Q(i,k) / T(i,k);
                %R(i,k) = Rchain(i,c) * ST(i,k) / STchain(i,c) * alpha(i,k) / sum(alpha(sn.refstat(k),inchain)');
            else
                T(i,k) = 0;
                R(i,k)=0;
                Q(i,k)=0;
            end
        end
        C(k) = sn.njobs(k) / X(k);
    end
end
runtime = toc(Tstart);
Q=abs(Q); R=abs(R); X=abs(X); U=abs(U); T=abs(T); C=abs(C);
T(~isfinite(T))=0; U(~isfinite(U))=0; Q(~isfinite(Q))=0; R(~isfinite(R))=0; X(~isfinite(X))=0; C(~isfinite(C))=0;
return
end
