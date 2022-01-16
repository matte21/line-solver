function [mu,c] = pfqn_fnc(alpha,c)
% generate rates for functional server f(n)=n+c
M = size(alpha,1);
if nargin<2
    c = zeros(1,M);
    mu = pfqn_fnc(alpha,c);
    if ~all(isfinite(mu)) % first retry with -1/2
        c = -0.5*ones(1,M);
        mu = pfqn_fnc(alpha,c);
    end
    dt = 0;
    it = 0;
    while ~all(isfinite(mu)) % randomize c if need be but unlikely
        it = it +1;
        dt = dt + 0.05;
        c = -1/2+dt;
        mu = pfqn_fnc(alpha,c);
        if c>=2
            break
        end
    end
    return
end
N = length(alpha(1,:));
mu = zeros(M,N);
for i=1:M
    mu(i,1) = alpha(i,1)/(1+c(i));
    for n=2:N
        rho = 0;
        for k=1:(n-1)
            rho = rho+(prod(alpha(i,(n-k+1):n))-prod(alpha(i,(n-k):(n-1))))/prod(mu(i,1:k));
        end
        mu(i,n) = (prod(alpha(i,1:n))/prod(mu(i,1:(n-1))));
        mu(i,n) = mu(i,n)/(1-rho);
    end
end
mu(isnan(mu)) = Inf;
mu(abs(mu)>1e15) = Inf;
for i=1:M
    if any(isinf(mu(i,:)))
        s = min(find(isinf(mu(i,:))));
        mu(i,s:end)=Inf;
    end
end
%mu(mu==0) = Inf;
end