function [ST,gamma,nservers,rho,ca,cs,eta] = npfqn_nonexp_approx(method,sn,ST,V,SCV,X,U,gamma,nservers)
% handler for non-exponential service and arrival processes
M = sn.nstations;
K = sn.nclasses;
rt = sn.rt;
rho = zeros(M,1);
ca = ones(M,1);
cs = ones(M,1);
eta = ones(M,1);
switch method
    case {'default','none'}
        % no-op
    case {'hvmva'}
        % no-op
    case {'interp'}
        T = zeros(M,K);
        for i=1:M
            nnzClasses = isfinite(ST(i,:)) & isfinite(SCV(i,:));
            rho(i) = sum(U(i,nnzClasses));
            T(i,:) = V(i,:).*X;
            switch sn.schedid(i)
                case SchedStrategy.ID_FCFS
                    if range(ST(i,nnzClasses))>0 && (max(SCV(i,nnzClasses))>1 - Distrib.Zero || min(SCV(i,nnzClasses))<1 + Distrib.Zero) % check if non-product-form                        
                        ca(i) = 1;
                        cs(i) = (SCV(i,nnzClasses)*T(i,nnzClasses)')/sum(T(i,nnzClasses));
                        
                        % multi-server asymptotic decay rate 
                        gamma(i) = (rho(i)^nservers(i)+rho(i))/2;
                        % single-server (diffusion approximation, Kobayashi JACM)
                        eta(i) = exp(-2*(1-rho(i))/(cs(i)+ca(i)*rho(i)));

                        % interpolation (Sec. 4.2, LINE paper at WSC 2020)
                        % ai, bi coefficient here set to the 8th power as
                        % numerically appears better than 4th power

                        % for all classes
                        for k=find(nnzClasses)
                            if sn.rates(i,k)>0
                                ST(i,k) = (1-rho(i)^8)*ST(i,k) + rho(i)^8*(gamma(i) + rho(i)^8* (eta(i)-gamma(i)))*(nservers(i)/sum(T(i,nnzClasses)));
                            end
                        end
                        % we are already account for multi-server effects
                        % in the scaled service times
                        nservers(i) = 1;
                    end
            end
        end
end
end
