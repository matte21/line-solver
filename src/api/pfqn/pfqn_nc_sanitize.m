function [lambda,L,N,Z,lGremaind] = pfqn_nc_sanitize(lambda,L,N,Z)
Tol = 1e-14;
% erase empty classes
nnzclasses=find(N);
L=L(:,nnzclasses);
N=N(:,nnzclasses);
Z=Z(:,nnzclasses);
lambda=lambda(:,nnzclasses);
% erase ill-defined classes
zeroclasses=find((L(:,nnzclasses)+Z(:,nnzclasses))<Distrib.Tol);
L(:,zeroclasses)=[];
N(:,zeroclasses)=[];
Z(:,zeroclasses)=[];
lambda(:,zeroclasses)=[];
% 
lGremaind= 0;
% find zero demand classes
zerodemands=find(L<Tol);
if ~isempty(zerodemands)
    lGremaind = lGremaind + N(zerodemands) * log(Z(zerodemands))' - sum(log(N(zerodemands)));
    L(:,zerodemands)=[];
    Z(:,zerodemands)=[];
    N(:,zerodemands)=[];
end
% rescale demands
Lmax = max(L,[],1); % use L, which has been santized to always be ~=0
L = L./repmat(Lmax,size(L,1),1);
Z = Z./repmat(Lmax,size(Z,1),1);
lGremaind = lGremaind + N*log(Lmax)';
% sort from smallest to largest think time
[~,rsort] = sort(Z,'ascend'); L=L(:,rsort); N=N(:,rsort); Z=Z(:,rsort);
% ensure zero think time classes are anyway frist
zerothinktimes=find(Z<Tol);
nonzerothinktimes = setdiff(1:size(L,2),zerothinktimes);
L=L(:,[zerothinktimes,nonzerothinktimes]);
N=N(:,[zerothinktimes,nonzerothinktimes]);
Z=Z(:,[zerothinktimes,nonzerothinktimes]);
end