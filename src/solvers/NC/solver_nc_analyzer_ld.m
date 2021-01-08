function [Q,U,R,T,C,X,runtime] = solver_nc_analyzer_ld(sn, options)
% [Q,U,R,T,C,X,RUNTIME] = SOLVER_NC_ANALYZER_LD(QN, OPTIONS)

% Copyright (c) 2012-2021, Imperial College London
% All rights reserved.

M = sn.nstations;    %number of stations
K = sn.nclasses;    %number of classes
S = sn.nservers;
NK = sn.njobs';  % initial population per class
C = sn.nchains;

PH = sn.proc;
%% initialization
% queue-dependent functions to capture multi-server and delay stations

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

[Xchain,Qchain]=pfqn_mvald(L,N,Z,mu);

%     Rchain = Qchain ./ repmat(Xchain,M,1) ./ Vchain;
%     Rchain(infServers,:) = Lchain(infServers,:) ./ Vchain(infServers,:);
%     Tchain = repmat(Xchain,M,1) .* Vchain;
%     Uchain = Tchain .* Lchain;
%     Cchain = Nchain ./ Xchain - Z;
%
%     Xchain(~isfinite(Xchain))=0;
%     Uchain(~isfinite(Uchain))=0;
%     Qchain(~isfinite(Qchain))=0;
%     Rchain(~isfinite(Rchain))=0;
%
%     Xchain(Nchain==0)=0;
%     Uchain(:,Nchain==0)=0;
%     Qchain(:,Nchain==0)=0;
%     Rchain(:,Nchain==0)=0;
%     Tchain(:,Nchain==0)=0;
%
%
%     for c=1:sn.nchains
%         inchain = find(sn.chains(c,:));
%         for k=inchain(:)'
%             X(k) = Xchain(c) * alpha(sn.refstat(k),k);
%             for i=1:sn.nstations
%                 if S(i) == -1
%                     U(i,k) = ST(i,k) * (Xchain(c) * Vchain(i,c) / Vchain(sn.refstat(k),c)) * alpha(i,k);
%                 else
%                     U(i,k) = ST(i,k) * (Xchain(c) * Vchain(i,c) / Vchain(sn.refstat(k),c)) * alpha(i,k) / S(i);
%                 end
%                 if Lchain(i,c) > 0
%                     Q(i,k) = Rchain(i,c) * ST(i,k) / STchain(i,c) * Xchain(c) * Vchain(i,c) / Vchain(sn.refstat(k),c) * alpha(i,k);
%                     T(i,k) = Tchain(i,c) * alpha(i,k);
%                     R(i,k) = Q(i,k) / T(i,k);
%                     %                R(i,k) = Rchain(i,c) * ST(i,k) / STchain(i,c) * alpha(i,k) / sum(alpha(sn.refstat(k),inchain)');
%                 else
%                     T(i,k) = 0;
%
%                     R(i,k)=0;
%                     Q(i,k)=0;
%                 end
%             end
%             C(k) = sn.njobs(k) / X(k);
%         end
%     end

% [G,lG] = pfqn_gmvald(Lchain, Nchain, mu_chain);
% for r=1:C
%     [Gr,lGr] = pfqn_gmvald(Lchain, oner(Nchain,r), mu_chain);
%     Xchain(r) = exp(lGr - lG);
%     for i=1:M
%         if Lchain(i,r)>0
%             if S(i) == -1 || isinf(S(i)) % infinite server
%                 Qchain(i,r) = Lchain(i,r) * Xchain(r);
%             else
%                 Qchain(i,r) = Zcorr(i,r) * Xchain(r) + Lcorr(i,r) * exp(pfqn_nc([Lcorr; Lcorr(i,:)],oner(Nchain,r),sum(Z,1)+sum(Zcorr,1), options) - lG);
%             end
%         end
%     end
% end
if isnan(Xchain)
    line_error(mfilename,'Normalizing constant computation produced floating-point range exception. Model is too large.');
end

runtime = toc(Tstart);

if options.verbose > 0
    line_printf('\nNC analysis completed. Runtime: %f seconds.\n',runtime);
end
return
end
