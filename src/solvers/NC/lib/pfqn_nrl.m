function [lG] = pfqn_nrl(L,N,Z,alpha,options)
if sum(N)<0
    lG=-Inf;
    return
end
if sum(N)==0
    lG=0;
    return
end
[M,R]=size(L);
Nt = sum(N);
if sum(Z)>0
    L = [L;Z];
    alpha(end+1,:)=1:Nt;
end
if M==1
    [~,lG] = pfqn_gld(L,N,alpha);
    return
else
    Lmax = max(L);
end
L = L./repmat(Lmax,size(L,1),1); % scale demands in [0,1]
x0 = zeros(1,R);
[~,~,lG] = laplaceapprox(@(x) infradius_h(x, L, N,alpha),x0);
lG = lG + N*log(Lmax');
end