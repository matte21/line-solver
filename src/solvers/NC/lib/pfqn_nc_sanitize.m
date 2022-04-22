function [lambda,L,N,Z,lGremaind] = pfqn_nc_sanitize(lambda,L,N,Z)
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
zerodemands=find(L<1e-6);
if ~isempty(zerodemands)
    lGremaind = lGremaind + N(zerodemands) * log(Z(zerodemands))' - sum(log(N(zerodemands)));
    L(zerodemands)=[];
    Z(zerodemands)=[];
    N(zerodemands)=[];
end
% find zero think time classes
%zerothinktimes=find(Z<1e-6);
%if ~isempty(zerothinktimes)
%    lGremaind = lGremaind + log(sum(N(zerothinktimes))) + N(zerothinktimes) * log(L(zerothinktimes))' - sum(log(N(zerothinktimes)));
%    L(zerothinktimes)=[];
%    Z(zerothinktimes)=[];
%    N(zerothinktimes)=[];
%end
end