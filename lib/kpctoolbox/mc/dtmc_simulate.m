function [sts]=dtmc_simulate(P, pi0, n)
% [sts]=dtmc_simulate(P, pi0, n)

[~,st] =  min(abs(rand-cumsum(pi0)));
F = cumsum(P,2);
for i=1:n    
    sts(i) = st; soujt(i)=1;    
    if F(st,end)==0 || P(st,st)==1        
        return;
    end
    st =  max([1,find( rand - F(st,:) > 0)]);
end
end