function lG=pfqn_comomrm(L,N,Z,m)
% comom for a finite repairment model
if size(L,1)~=1
    line_error(mfilename,'The solver accepts at most a single queueing station.')
end
if nargin<4
    m=1;
end
lambda = 0*N;
[~,L,N,Z,lG0] = pfqn_nc_sanitize(lambda,L,N,Z);
[M,R]=size(L);
% rescale demands
Lmax = L; % use L, which has been santized to always be ~=0
L = L./repmat(Lmax,M,1);
Z = Z./repmat(Lmax,M,1);
% sort from smallest to largest
[~,rsort] = sort(Z,'ascend'); L=L(:,rsort); Z=Z(:,rsort);
zerothinktimes=find(Z<1e-6);
% ensure zero think time classes are anyway last
nonzerothinktimes = setdiff(1:R,zerothinktimes);
L=L(:,[nonzerothinktimes,zerothinktimes]);
Z=Z(:,[nonzerothinktimes,zerothinktimes]);
% initialize
nvec=zeros(1,R);
h=ones(2,1);
lh=log(h) + factln(sum(nvec)+M-1) - sum(factln(nvec));
h=exp(lh);
scale=zeros(1,sum(N));
% iterate
for r=1:R
    for Nr=1:N(r)
        nvec(r)=nvec(r)+1;
        if Nr==1
            if r>1
                hr = zeros(2*r,1);
                hr(1:(r-1)) = h(1:(r-1));
                hr((r+1):(2*r-1)) = h(((r-1)+1):2*(r-1));
                h=hr;
                % update scalings
                h(r)=h_1(1)*nvec((r-1))/(sum(nvec)-1)/scale(nt);
                h(end)=h_1((r-1)+1)*nvec((r-1))/(sum(nvec)-1)/scale(nt);
            end
            % CE for G+
            A12(1,1) = -1;
            % Class-1..(R-1) PCs for G
            for s=1:(r-1)
                A12(1+s,1) = N(s);
                A12(1+s,1+s) = -Z(s);
            end
            % Class-R PCs
            B2r = [m*L(1,r)*eye(r), Z(r)*eye(r)];
            % explicit formula for inv(C)
            iC=-eye(r)/m;
            iC(1,:)=-1/m;
            iC(1)=1;
            % explicit formula for F1r
            F1r = zeros(2*r); F1r(1,1)=1;
            % F2r by the definition
            F2r = [-iC*A12*B2r; B2r];
        end
        h_1 = h;
        h = (nvec(r)*F1r+F2r)*h_1/(sum(nvec)+M-1);
        nt = sum(nvec);
        scale(nt) = abs(sum(sort(h)));
        h = abs(h)/scale(nt); % rescale so that |h|=1
    end
end
% unscale and return the log of the normalizing constant
lG = lG0 + log(h(end-(R-1))) + factln(sum(N)+M-1) - sum(factln(N)) + N*log(Lmax)' + sum(log(scale));
end