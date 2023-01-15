function [T,Q,U,R] = pfqn_linearizerms(L,N,Z,nservers)
% Multiserver version of Krzesinski's Linearizer as described in Conway 
% 1989,  Fast Approximate Solution of Queueing Networks with Multi-Server 
% Chain- Dependent FCFS Queues.
% Some minor adjustments based on De Souza-Muntz's description of the 
% algorithm.

[M,R]=size(L);

% Initialize
Q = zeros(M,R,1+R);
PB = zeros(M,1+R);
P = zeros(M,max(nservers),1+R);
Delta = zeros(M,R,R);
for i=1:M
    for r=1:R
        for s=1:R
            Delta(i,r,s) = 0;
            N_1 = oner(N,s);
            Q(i,r,1+s) = N_1(r)/M;
        end
    end
end
for i=1:M
    for r=1:R
        for s=0:R
            N_1 = oner(N,s);
            pop = sum(N_1);
            if nservers(i)>1
                for j=1:(nservers(i)-1)
                    P(i,1+j,1+s) = 2*sum(Q(i,:,1+s))/(pop*(pop+1));
                end
                PB(i,1+s) = 2*sum(Q(i,:,1+s))/(pop+1-nservers(i))/(pop*(pop+1));
                P(i,1+0,1+s) = 1 - PB(i,1+s) - sum(P(i,1+(1:(nservers(i)-1)),1+s));
            end
        end
    end
end

% Main loop
for I=1:2
    for s=0:R
        N_1 = oner(N,s); % for k=0 it just returns N
        % Core(N_1)
        [Q(:,:,1+s),~,~,P(:,:,1+s),PB(:,1+s)] = Core(L,M,R,N_1,Z,nservers,Q(:,:,1+s),P(:,:,1+s),PB(:,1+s),Delta);
    end
    % Update_Delta
    for i=1:M
        for r=1:R
            for s=1:R
                Ns = oner(N,s);
                Delta(i,r,s) = Q(i,r,1+s)/Ns(r) - Q(i,r,1+0)/N(r);
            end
        end
    end
end

% Core(N)
[Q,W,T,~,~] = Core(L,M,R,N,Z,nservers,Q(:,:,1+0),P(:,:,1+0),PB(:,1+0),Delta);
% Compute performance metrics
U = zeros(M,R);
for i=1:M
    for r=1:R
        if nservers(i)==1
            U(i,r)=T(r)*L(i,r);
        else
            U(i,r)=NaN;%1-PB(i,1+r);
        end
    end
end
Q = Q(1:M,1:R,1+0);
R = W;
end

function [Q,W,T,P,PB] = Core(L,M,R,N_1,Z,nservers,Q,P,PB,Delta)
hasConverged = false;
while ~hasConverged
    Qlast = Q;
    % Estimate population at
    [Q_1,P_1,PB_1] = Estimate(M,R,N_1,nservers,Q,P,PB,Delta);
    % Forward MVA
    [Q,W,T,P,PB] = ForwardMVA(L,M,R,N_1,Z,nservers,Q_1,P_1,PB_1);
    if norm(Q-Qlast)<1e-8
        hasConverged = true;
    end
end % it
end

function [Q_1,P_1,PB_1] = Estimate(M,R,N_1,nservers,Q,P,PB,Delta)
P_1 = zeros(M,max(nservers),1+R);
PB_1 = zeros(M,1+R);
Q_1 = zeros(M,R);
for i=1:M
    if nservers(i)>1
        for j=0:(nservers(i)-1)
            for s=0:R
                P_1(i,1+j,1+s) = P(i,1+j);
            end
        end
        for s=0:R
            PB_1(i,1+s) = PB(i,1);
        end
    end
    for r=1:R
        for s=1:R
            Ns = oner(N_1,s);
            Q_1(i,r,1+s) = Ns(r)*(Q(i,r,1+0)/N_1(r) + Delta(i,r,s));
        end
    end
end
end

function [Q,W,T,P,PB] = ForwardMVA(L,M,R,N_1,Z,nservers,Q_1,P_1,PB_1)
W = zeros(M,R);
T = zeros(1,R);
Q = zeros(M,R);
P = zeros(M,max(nservers));
PB = zeros(M,1);
for i=1:M
    for r=1:R
        W(i,r) = (L(i,r)/nservers(i))*(1+sum(Q_1(i,:,1+r)));
        if nservers(i) > 1
            for j=0:(nservers(i)-2)
                W(i,r) = W(i,r) + L(i,r)*(nservers(i)-1-j)*P_1(i,1+j,1+r);
            end
        end
    end
end
for r=1:R
    T(r) = N_1(r) / (Z(r)+sum(W(:,r)));
    for i=1:M
        Q(i,r) = T(r) * W(i,r);
    end
end
for i=1:M
    if nservers(i) > 1
        P(i,:) = 0;
        for j=1:(nservers(i)-1)
            for s=1:R
                P(i,1+j) = P(i,1+j) + L(i,s)*T(s)*P_1(i,1+(j-1),1+s)/j;
            end
        end
    end
end
for i=1:M
    if nservers(i) > 1
        PB(i) = 0;
        for s=1:R
            PB(i) = PB(i) + L(i,s)*T(s)*(PB_1(i,1+s)+P_1(i,1+nservers(i)-1,1+s))/nservers(i);
        end
    end
end
for i=1:M
    if nservers(i) > 1
        P(i,1+0) = 1 - PB(i);
        for j=1:(nservers(i)-1)
            P(i,1+0) = P(i,1+0) - P(i,1+j);
        end
    end
end
end