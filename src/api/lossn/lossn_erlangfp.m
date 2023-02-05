function [QLen,Loss,E] = lossn_erlangfp(nu,A,C)
% [QLen,Loss,E] = LOSS_ERLANGFP(rho,A,C)
% Erlang fixed point approximation for loss networks
%
% Calls (i.e., jobs) on route (i.e., class) r arrive according to Poisson
% rate nu_r, r=1..R. Call service times on route r have unit mean.
% 
% Link capacity requirements are:
%                        \sum_r A(j,r) n(j,r) <= C(j)
% for all links j=1..J, where n(j,r) counts the calls on route r on link j.
%
% INPUT:
% nu  (1xR): arv. rate of route (class) r = 1..R
% A   (J,R): capacity requirement of link j for route r = 1..R
% C   (J,1): available capacity of link j
%
% OUTPUT:
% Q   (1xR): mean queue-length for route r = 1..R calls
% L   (1xR): loss probability for route r = 1..R calls
% E   (Jx1): blocking probability of for link j = 1..J 
%
% NOTE: nu_r may be replaced by a utilization rho_r=nu_r/mu_r, where mu_r 
% is the service rate for route r.

R = length(nu);
J = length(C);
E = 0.5*ones(J,1);
E_1 = 0*ones(J,1);
while norm(E-E_1,1)>1e-8
    E_1 = E;
    for j=1:J
        rhoj_1 = 0;
        for r=1:R
            if A(j,r)>0
                termj=nu(r)*A(j,r);
                for i=1:J
                    if A(i,r)>0
                        termj=termj*(1-E_1(i))^A(i,r);
                    end
                end
                rhoj_1 = rhoj_1 + termj;
            end
        end
        rhoj_1 = rhoj_1 / (1-E_1(j));
        E(j) = erlang_formula(rhoj_1,C(j));
    end
end
QLen = nu;
for r=1:R
    for j=1:J
        QLen(r) = QLen(r)*(1-E(j))^A(j,r);
    end
end
QLen = real(QLen);
Loss = QLen./nu;
end

function blockProb = erlang_formula(nu,C)
% Erlang formula
% blockProb = E(nu,C) = (nu^C/C!) / (sum_{i=1}^C nu^i/i!) 
den = 0;
for i=0:C
    d = i*log(nu)-factln(i);
    den = den + exp(d);
end
blockProb = C*log(nu) -factln(C) -log(den);
blockProb = exp(blockProb);
end
