function [lGN,Cgamma] = pfqn_rd(L,N,Z,mu)
if sum(N)<0
    lGN=-Inf;
    return
end
if sum(N)==0
    lGN=0;
    return
end
if min(mu(:))==max(mu(:))
    options = SolverNC.defaultOptions;
    lGN = pfqn_nc(L/mu(1),N,Z,options);
    return
end

[M,R]=size(L);
gamma = ones(M,sum(N));
mu = mu(:,1:sum(N));
s = sum(N)*ones(1,M);
for i=1:M
    gamma(i,:) = mu(i,:)/mu(i,s(i));
end

beta = ones(M,sum(N));
for i=1:M
    beta(i,1) = gamma(i,1) / (1-gamma(i,1)) ;
    for j=2:sum(N)
        beta(i,j) = (1-gamma(i,j-1)) * (gamma(i,j) / (1-gamma(i,j)));
    end
end
beta(isnan(beta))=Inf;
beta(isinf(beta))=Inf;

y = L;
for i=1:M
    y(i,:) = y(i,:) / (mu(i,end));
end

Cgamma=0;
sld = s(s>1);
vmax = min(sum(sld-1),sum(N));

Y = pfqn_aql(y,N,Z);
[~,~,~,~,lEN,isNumStable] = pfqn_mvald(y*Y',vmax,0,beta);
%[~,~,lEN] = gmvaldsingle(y*Y',vmax,beta);

for vtot=0:vmax
    EN = exp(lEN(vtot+1));
    Cgamma = Cgamma + ((sum(N)-max(0,max(vtot-1)))/sum(N)) * EN;
end
%[~,lGN] = pfqn_mci(y,N,Z,1e5);
options = SolverNC.defaultOptions;
if sum(Z)>0
    options.method='comom';
else
    options.method='adaptive';
end
lGN = pfqn_nc(y,N,Z,options);
%[~,lGN] = pfqn_ca(y,N,Z);
lGN = lGN + log(Cgamma);
end

function [G,g,lGN]=gmvaldsingle(L,N,mu)
[M,R]=size(L);
scaleFactor = max(L,[],1);
L=L./repmat(scaleFactor,M,1);
g=zeros(M+1,N+1,1+1);
g(1,1,1)=L(1,1)*0;
for n=1:N
    g(0 +1,n +1, 1 +1)=0;
end
for m=1:M
    for tm=1:(N+1)
        g(m +1,0 +1,tm +1)=1;
    end
    for n=1:N
        for tm=1:(N-n+1)
            g(m +1, n +1, tm +1)= g(m-1 +1, n +1, 1 +1)+L(m)*g(m +1, n-1 +1, tm+1 +1)/mu(m,tm);
        end
    end
end
G=scaleFactor^sum(N)*g(M+1,N+1,1+1);
lGN=log(g(M+1,:,1+1))+sum(N)*log(scaleFactor);
end