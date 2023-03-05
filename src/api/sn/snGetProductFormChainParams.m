function [lambda,D,N,Z,mu,S,V]= snGetProductFormChainParams(sn)
% [LAMBDA,D,N,Z,MU,S,V]= NETWORKSTRUCT_GETPRODUCTFORMCHAINPARAMS(SN)

% mu also returns max(S) elements after population |N| as this is
% required by MVALDMX

[lambda,~,~,~,mu,~] = snGetProductFormParams(sn);
[Dchain,~,Vchain,alpha,Nchain,~,~] = snGetDemandsChain(sn);
lambda_chains = zeros(1,sn.nchains);
for c=1:sn.nchains
    lambda_chains(c) = sum(lambda(sn.inchain{c}));
    %if sn.refclass(c)>0
        %D_chains(:,c) = Dchain(find(isfinite(sn.nservers)),c)/alpha(sn.refstat(c),sn.refclass(c));
        %Z_chains(:,c) = Dchain(find(isinf(sn.nservers)),c)/alpha(sn.refstat(c),sn.refclass(c));
    %else
        D_chains(:,c) = Dchain(find(isfinite(sn.nservers)),c);
        Z_chains(:,c) = Dchain(find(isinf(sn.nservers)),c);
    %end
end
S = sn.nservers(find(isfinite(sn.nservers)));
lambda = lambda_chains;
N = Nchain;
D = D_chains;
Z = Z_chains;
V = Vchain;
if isempty(Z)
    Z = 0*N;
end
end

