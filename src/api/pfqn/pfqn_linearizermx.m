function [QN,UN,WN,CN,XN,totiter] = pfqn_linearizermx(lambda,L,N,Z,nservers,type,tol,maxiter)
% function [Q,U,W,C,X,totiter] = PFQN_LINEARIZERMX(lambda,L,N,Z,nservers,type,tol,maxiter)

if nargin<4
    maxiter = 1000;
end
if nargin<5
    tol = 1e-8;
end

if any(N(lambda>0)>0 & isfinite(N(lambda>0)))
    line_error(mfilename,'Arrival rate cannot be specified on closed classes.');
end

[M,R] = size(L);

lambda(isnan(lambda))= 0;
L(isnan(L))=0;
Z(isnan(Z))=0;
openClasses = find(isinf(N));
closedClasses = setdiff(1:length(N), openClasses);

XN = zeros(1,R);
UN = zeros(M,R);
WN = zeros(M,R);
QN = zeros(M,R);
CN = zeros(1,R);
for r=openClasses
    for i=1:M
        UN(i,r) = lambda(r)*L(i,r);
    end
    XN(r) = lambda(r);
end

UNt = sum(UN,2);

if isempty(Z)
    Z = zeros(1,R);
else
    Z = sum(Z,1);
end
Dc = L(:,closedClasses) ./ (1-repmat(UNt,1,length((closedClasses))));

if max(nservers)==1
    [QNc,UNc,WNc,CNc,XNc,totiter] = pfqn_linearizer(Dc,N(closedClasses),Z(closedClasses),type,tol,maxiter);
else
    [QNc,UNc,WNc,CNc,XNc,totiter] = pfqn_linearizerms(Dc,N(closedClasses),Z(closedClasses),nservers,type,tol,maxiter);
end

XN(closedClasses) = XNc;
QN(:,closedClasses) = QNc;
WN(:,closedClasses) = UNc;
UN(:,closedClasses) = WNc;
CN(closedClasses) = CNc;

for i = 1:M
    for r=closedClasses
        UN(i,r) = XN(r)*L(i,r);
    end
end
for i = 1:M
    for r=openClasses
        if isempty(QNc)
            WN(i,r) = L(i,r) / (1-UNt(i));
        else
            WN(i,r) = L(i,r) * (1+sum(QNc(i,:))) / (1-UNt(i));
        end
        QN(i,r) = WN(i,r) * XN(r);
    end
end
CN(openClasses) = sum(WN(:,openClasses),1);
end
