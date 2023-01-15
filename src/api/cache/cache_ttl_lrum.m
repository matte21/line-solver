function prob=cache_ttl_lrum(gamma,m)
gamma = gamma(1,:,2:end);
gamma = reshape(gamma,size(gamma,2),size(gamma,3));
[n,h]=size(gamma);
t = cache_t_lrum(gamma,m);  % the characteristic time of each list, a total of h lists

probh = zeros(n,h);   % steady state 1,...,h
prob0 = zeros(n,1);   % steady state 0
trans = zeros(n,h);
denom = zeros(1,n);

for k =1:n
    for j = 1:h
        trans(k,j) = exp(gamma(k,j)*t(j))-1;  %birth and death        
    end
    denom(k) = sum(cumprod(trans(k,:)));
end

for k = 1:n
    for l = 1:h
        probh(k,l) = prod(trans(k,1:l))/(1+denom(k));
    end
    prob0(k) = 1-sum(probh(k,:));
end
prob = [prob0 probh];
end