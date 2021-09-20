function [Wchain, STeff] = solver_amva_iter(sn, gamma, tau, Qchain, Xchain, Uchain, STchain, Vchain, Nchain, SCVchain, options)

M = sn.nstations;
K = sn.nchains;
nservers = sn.nservers;
schedparam = sn.schedparam;
lldscaling = sn.lldscaling;
cdscaling = sn.cdscaling;

%Uhiprio = zeros(M,K); % utilization due to "permanent jobs" in DPS

if isempty(gamma)
    gamma = zeros(M,K);
end

Nt = sum(Nchain(isfinite(Nchain)));
if all(isinf(Nchain))
    delta = 1;
else
    delta = (Nt - 1) / Nt;
end
deltaclass = (Nchain - 1) ./ Nchain;
deltaclass(isinf(Nchain)) = 1;

nnzclasses = find(Nchain>0);
nnzclasses_eprio = {};
nnzclasses_hprio = {};
nnzclasses_ehprio = {};
for r = nnzclasses
    nnzclasses_eprio{r} = intersect(nnzclasses, find(sn.classprio == sn.classprio(r))); % equal prio
    nnzclasses_hprio{r} = intersect(nnzclasses, find(sn.classprio > sn.classprio(r))); % higher prior
    nnzclasses_ehprio{r} = intersect(nnzclasses, find(sn.classprio >= sn.classprio(r))); % equal or higher prio
end

ocl = find(isinf(Nchain));
ccl = find(isfinite(Nchain) & Nchain>0);

%% evaluate lld and cd correction factors
totArvlQlenSeenByOpen = zeros(K,M,1);
interpTotArvlQlen = zeros(M,1);
totArvlQlenSeenByClosed = zeros(M,K);
stationaryQlen = zeros(M,K);
selfArvlQlenSeenByClosed = zeros(M,K);
for k=1:M
    interpTotArvlQlen(k) = delta * sum(Qchain(k,nnzclasses));
    for r = nnzclasses
        selfArvlQlenSeenByClosed(k,r) = deltaclass(r) * Qchain(k,r); % qlen of same class as arriving one
        switch sn.schedid(k)
            case {SchedStrategy.ID_HOL}
                totArvlQlenSeenByOpen(r,k) = sum(Qchain(k,nnzclasses_ehprio{r}));
                totArvlQlenSeenByClosed(k,r) = deltaclass(r) * Qchain(k,r) + sum(Qchain(k,setdiff(nnzclasses_ehprio{r},r)));
            otherwise
                totArvlQlenSeenByOpen(r,k) = sum(Qchain(k,nnzclasses));
                totArvlQlenSeenByClosed(k,r) = deltaclass(r) * Qchain(k,r) + sum(Qchain(k,setdiff(nnzclasses,r)));
        end
        stationaryQlen(k,r) = Qchain(k,r); % qlen of same class as arriving one
    end
end

%% high variance handling
STchain0 = STchain;
switch options.config.highvar
    case {'default'}
        % no-op        
    case {'interp'}
        for i=1:M
            sd = isfinite(STchain(i,:)) & isfinite(SCVchain(i,:));
            rho(i) = sum(Uchain(i,sd));
            T(i,:) = Vchain(i,:).*Xchain;
            switch sn.schedid(i)
                case SchedStrategy.ID_FCFS
                    if range(STchain(i,sd))>0 && (max(SCVchain(i,sd))>1 - Distrib.Zero || min(SCVchain(i,sd))<1 + Distrib.Zero) % check if non-product-form
                        ca(i) = 1;
                        cs(i) = (SCVchain(i,sd)*T(i,sd)')/sum(T(i,sd));
                        gamma(i) = (rho(i)^nservers(i)+rho(i))/2; % multi-server
                        % asymptotic decay rate (diffusion approximation, Kobayashi JACM)
                        eta(i) = exp(-2*(1-rho(i))/(cs(i)+ca(i)*rho(i)));
                        for k=find(sd)
                            if STchain(i,k)>0
                                STchain(i,k) = (1-rho(i)^8)*STchain0(i,k) + rho(i)^8*(gamma(i) + rho(i)^8* (eta(i)-gamma(i)))*(nservers(i)/sum(T(i,sd)));                                
                            end
                        end
                        nservers(i) = 1;
                    end
            end
        end
end

%% all methods use LLD and CD corrections from QD-AMVA
if isempty(lldscaling)
    lldscaling = ones(M,Nt);
end
lldterm = pfqn_lldfun(1 + interpTotArvlQlen, lldscaling);

cdterm = ones(M,K);
for r=nnzclasses
    if ~isempty(cdscaling)
        if isfinite(Nchain(r))
            cdterm(:,r) = pfqn_cdfun(1 + selfArvlQlenSeenByClosed, cdscaling); % qd-amva class-dependence term
        else
            cdterm(:,r) = pfqn_cdfun(1 + stationaryQlen, cdscaling); % qd-amva class-dependence term
        end
    end
end

switch options.config.multiserver
    case 'softmin'
        switch options.method
            case {'default','amva.lin','lin', 'amva.qdlin','qdlin'} % Linearizer
                g = 0;
                for r=ccl
                    g = g + ((Nt-1)/Nt) * Nchain(r) * gamma(ccl,k,r);
                end
                msterm = pfqn_lldfun(1 + interpTotArvlQlen + mean(g), [], nservers); % if native qd then account for multiserver in the correciton terms
            otherwise
                msterm = pfqn_lldfun(1 + interpTotArvlQlen + (Nt-1)*mean(gamma(ccl,k)), [], nservers); % if native qd then account for multiserver in the correciton terms
        end
    case 'seidmann'
        msterm = ones(M,1) ./ nservers(:);
        msterm(msterm==0) = 1; % infinite server case
    case 'default'
        switch options.method
            case {'default','amva.lin','lin','amva.qdlin','qdlin'} % Linearizer
                g = 0;
                for r=ccl
                    g = g + ((Nt-1)/Nt) * Nchain(r) * gamma(ccl,k,r);
                end
                msterm = pfqn_lldfun(1 + interpTotArvlQlen + mean(g), [], nservers); % if native qd then account for multiserver in the correciton terms
            otherwise
                g = 0;
                for r=ccl
                    g = g + (Nt-1)*gamma(r,k);
                end
                msterm = pfqn_lldfun(1 + interpTotArvlQlen + mean(g), [], nservers); % if native qd then account for multiserver in the correciton terms
        end
        fcfstypeset = find(sn.schedid==SchedStrategy.ID_FCFS | sn.schedid==SchedStrategy.ID_SIRO | sn.schedid==SchedStrategy.ID_LCFSPR);
        msterm(fcfstypeset) = 1 ./ nservers(fcfstypeset);
    otherwise
        line_error(mfilename,'Unrecognize multiserver approximation method');
end

Wchain = zeros(M,K);

STeff = zeros(size(STchain)); % effective service time
for r=nnzclasses
    for k=1:M
        STeff(k,r) = STchain(k,r) * lldterm(k) * msterm(k) * cdterm(k,r);
    end
end

%% if amva.qli or amva.fli, update now totArvlQlenSeenByClosed with STeff
switch options.method
    case {'amva.qli','qli'} % Wang-Sevcik queue line
        infset = sn.schedid == SchedStrategy.ID_INF;
        for k=1:M
            switch sn.schedid(k)
                case {SchedStrategy.ID_HOL}
                    for r = nnzclasses
                        if Nchain(r) == 1
                            totArvlQlenSeenByClosed(k,r) = sum(Qchain(k,nnzclasses_ehprio{r})) - Qchain(k,r);
                        else
                            qlinum = STeff(k,r) * (1+sum(Qchain(k,nnzclasses_ehprio{r})) - Qchain(k,r));
                            qliden = sum(STeff(infset,r));
                            for m=1:M
                                qliden = qliden + STeff(m,r) * (1+sum(Qchain(m,nnzclasses_ehprio{r})) - Qchain(m,r));
                            end
                            totArvlQlenSeenByClosed(k,r) = sum(Qchain(k,nnzclasses_ehprio{r})) - (1/(Nchain(r)-1))*(Qchain(k,r) - qlinum/qliden);
                        end
                    end
                otherwise
                    for r = nnzclasses
                        if Nchain(r) == 1
                            totArvlQlenSeenByClosed(k,r) = sum(Qchain(k,nnzclasses)) - Qchain(k,r);
                        else
                            qlinum = STeff(k,r) * (1+sum(Qchain(k,nnzclasses)) - Qchain(k,r));
                            qliden = sum(STeff(infset,r));
                            for m=1:M
                                qliden = qliden + STeff(m,r) * (1+sum(Qchain(m,nnzclasses)) - Qchain(m,r));
                            end
                            totArvlQlenSeenByClosed(k,r) = sum(Qchain(k,nnzclasses)) - (1/(Nchain(r)-1))*(Qchain(k,r) - qlinum/qliden);
                        end
                    end
            end
        end
    case {'amva.fli','fli'} % Wang-Sevcik fraction line
        infset = sn.schedid == SchedStrategy.ID_INF;
        for k=1:M
            switch sn.schedid(k)
                case {SchedStrategy.ID_HOL}
                    for r = nnzclasses
                        if Nchain(r) == 1
                            totArvlQlenSeenByClosed(k,r) = sum(Qchain(k,nnzclasses_ehprio{r})) - Qchain(k,r);
                        else
                            qlinum = STeff(k,r) * (1+sum(Qchain(k,nnzclasses_ehprio{r})) - Qchain(k,r));
                            qliden = sum(STeff(infset,r));
                            for m=1:M
                                qliden = qliden + STeff(m,r) * (1+sum(Qchain(m,nnzclasses_ehprio{r})) - Qchain(m,r));
                            end
                            totArvlQlenSeenByClosed(k,r) = sum(Qchain(k,nnzclasses_ehprio{r})) - (2/Nchain(r))*Qchain(k,r) + qlinum/qliden;
                        end
                    end
                otherwise
                    for r = nnzclasses
                        if Nchain(r) == 1
                            totArvlQlenSeenByClosed(k,r) = sum(Qchain(k,nnzclasses)) - Qchain(k,r);
                        else
                            qlinum = STeff(k,r) * (1+sum(Qchain(k,nnzclasses)) - Qchain(k,r));
                            qliden = sum(STeff(infset,r));
                            for m=1:M
                                qliden = qliden + STeff(m,r) * (1+sum(Qchain(m,nnzclasses)) - Qchain(m,r));
                            end
                            totArvlQlenSeenByClosed(k,r) = sum(Qchain(k,nnzclasses)) - (2/Nchain(r))*Qchain(k,r) + qlinum/qliden;
                        end
                    end
                    
            end
        end
end

%% compute response times from current queue-lengths
for r=nnzclasses
    sd = setdiff(nnzclasses,r);
    sdprio = setdiff(nnzclasses_ehprio{r},r);
    
    for k=1:M
        
        switch sn.schedid(k)
            case SchedStrategy.ID_INF
                Wchain(k,r) = STeff(k,r);
                
            case SchedStrategy.ID_PS
                switch options.method
                    case {'default', 'amva', 'amva.qd', 'amva.qdamva', 'qd', 'qdamva', 'lin', 'qdlin'} % QD-AMVA interpolation
                        switch options.config.multiserver
                            case 'seidmann' % in this case, qd handles only lld and cd scalings
                                Wchain(k,r) = STeff(k,r) * (nservers(k)-1); % multi-server correction with serial think time, (1/nservers(k)) term already in STeff
                                if ismember(r,ocl)
                                    Wchain(k,r) = Wchain(k,r) + STeff(k,r) * (1 + totArvlQlenSeenByOpen(r,k));
                                else
                                    switch options.method
                                        case {'default', 'amva.lin', 'lin', 'amva.qdlin','qdlin'} % Linearizer
                                            Wchain(k,r) = Wchain(k,r) + STeff(k,r) * (1 + interpTotArvlQlen(k) + Nchain(ccl)*permute(gamma(r,k,ccl),3:-1:1) - gamma(r,k,r));
                                        otherwise
                                            Wchain(k,r) = Wchain(k,r) + STeff(k,r) * (1 + interpTotArvlQlen(k) + (Nt-1)*gamma(r,k));
                                    end
                                end
                            case {'default','softmin'}
                                if ismember(r,ocl)
                                    Wchain(k,r) = STeff(k,r) * (1 + totArvlQlenSeenByOpen(r,k));
                                else
                                    switch options.method
                                        case {'default', 'amva.lin', 'lin', 'amva.qdlin','qdlin'} % Linearizer
                                            Wchain(k,r) = Wchain(k,r) + STeff(k,r) * (1 + interpTotArvlQlen(k) + Nchain(ccl)*permute(gamma(r,k,ccl),3:-1:1) - gamma(r,k,r));
                                        otherwise
                                            Wchain(k,r) = STeff(k,r) * (1 + interpTotArvlQlen(k) + (Nt-1)*gamma(r,k));
                                    end
                                end
                        end
                    otherwise % Bard-Schweitzer interpolation and Wang-Sevcik algorithms
                        switch options.config.multiserver
                            case 'seidmann'
                                Wchain(k,r) = STeff(k,r) * (nservers(k)-1); % multi-server correction with serial think time, (1/nservers(k)) term already in STeff
                                if ismember(r,ocl)
                                    Wchain(k,r) = Wchain(k,r) + STeff(k,r) * (1 + totArvlQlenSeenByOpen(r,k));
                                else
                                    switch options.method
                                        case {'default', 'amva.lin', 'lin', 'amva.qdlin','qdlin'} % Linearizer
                                            Wchain(k,r) = Wchain(k,r) + STeff(k,r) * (1 + totArvlQlenSeenByClosed(k) + Nchain(ccl)*permute(gamma(r,k,ccl),3:-1:1) - gamma(r,k,r));
                                        otherwise
                                            Wchain(k,r) = Wchain(k,r) + STeff(k,r) * (1 + totArvlQlenSeenByClosed(k) + (Nt-1)*gamma(r,k));
                                    end
                                end
                            case {'default','softmin'}
                                if ismember(r,ocl)
                                    Wchain(k,r) = Wchain(k,r) + STeff(k,r) * (1 + totArvlQlenSeenByOpen(r,k));
                                else
                                    switch options.method
                                        case {'default', 'amva.lin', 'lin', 'amva.qdlin','qdlin'} % Linearizer
                                            Wchain(k,r) = Wchain(k,r) + STeff(k,r) * (1 + totArvlQlenSeenByClosed(k) + Nchain(ccl)*permute(gamma(r,k,ccl),3:-1:1) - gamma(r,k,r));
                                        otherwise
                                            Wchain(k,r) = Wchain(k,r) + STeff(k,r) * (1 + totArvlQlenSeenByClosed(k) + (Nt-1)*gamma(r,k));
                                    end
                                end
                        end
                end
                
            case SchedStrategy.ID_DPS
                if nservers(k)>1
                    line_error(mfilename,'Multi-server DPS not supported yet in AMVA solver.')
                else
                    w = schedparam; % DPS weight
                    tss = Inf; % time-scale separation threshold, this was originally at 5, presently it is disabled
                    %Uhiprio(k,r) = sum(Uchain(k,w(k,:)>tss*w(k,r))); % disabled at the moment
                    %STeff(k,r) = STeff(k,r) / (1-Uhiprio(k,r));
                    
                    Wchain(k,r) = STeff(k,r) * (1 + selfArvlQlenSeenByClosed(k,r)); % class-r
                    for s=sd  % slowdown due to classes s!=r
                        if w(k,s) == w(k,r) % handle gracefully 0/0 case
                            Wchain(k,r) = Wchain(k,r) + STeff(k,r) * stationaryQlen(k,s);
                        elseif w(k,s)/w(k,r)<=tss
                            Wchain(k,r) = Wchain(k,r) + STeff(k,r) * stationaryQlen(k,s) * w(k,s)/w(k,r);
                        elseif w(k,s)/w(k,r)>tss
                            % if there is time-scale separation, do nothing
                            % all is accounted for by 1/(1-Uhiprio)
                        end
                    end
                end
                
            case {SchedStrategy.ID_FCFS, SchedStrategy.ID_SIRO, SchedStrategy.ID_LCFSPR}
                if STeff(k,r) > 0
                    Uchain_r = Uchain ./ repmat(Xchain,M,1) .* (repmat(Xchain,M,1) + repmat(tau(r,:),M,1));
                    
                    if nservers(k)>1
                        if sum(deltaclass .* Xchain .* Vchain(k,:) .* STeff(k,:)) < 0.75 % light-load case
                            switch options.config.multiserver
                                case 'softmin'
                                    Bk = ((deltaclass .* Xchain .* Vchain(k,:) .* STeff(k,:))); % note: this is in 0-1 as a utilization
                                case {'default','seidmann'}
                                    Bk = ((deltaclass .* Xchain .* Vchain(k,:) .* STeff(k,:)) / nservers(k)); % note: this is in 0-1 as a utilization
                            end
                        else % high-load case
                            switch options.config.multiserver
                                case 'softmin'
                                    Bk = (deltaclass .* Xchain .* Vchain(k,:) .* STeff(k,:)).^nservers(k); % Rolia
                                case {'default','seidmann'}
                                    Bk = (deltaclass .* Xchain .* Vchain(k,:) .* STeff(k,:) / nservers(k)).^nservers(k); % Rolia
                            end
                        end
                    else
                        Bk = ones(1,K);
                    end
                    
                    if nservers(k)==1 && (~isempty(lldscaling) || ~isempty(cdscaling))
                        switch options.config.highvar % high SCV
                            case 'hvmva'
                                Wchain(k,r) = STeff(k,r) * (1-sum(Uchain_r(k,ccl)));
                                for s=ccl
                                    Wchain(k,r) = Wchain(k,r) + STeff(k,s) * Uchain_r(k,s) * (1 + SCVchain(k,s))/2; % high SCV
                                end
                            otherwise % default
                                Wchain(k,r) = STeff(k,r);
                        end
                        if any(ismember(ocl,r))
                            Wchain(k,r) = Wchain(k,r) + (STeff(k,r) * stationaryQlen(k,r) + STeff(k,sd)*stationaryQlen(k,sd)');
                        else
                            switch options.method
                                case {'default', 'amva.lin', 'lin', 'amva.qdlin','qdlin'} % Linearizer
                                    Wchain(k,r) = Wchain(k,r) + (STeff(k,r) * selfArvlQlenSeenByClosed(k,r) + STeff(k,sd)*stationaryQlen(k,sd)') + (STeff(k,ccl).*Nchain(ccl)*permute(gamma(r,k,ccl),3:-1:1) - STeff(k,r)*gamma(r,k,r));
                                otherwise
                                    Wchain(k,r) = Wchain(k,r) + (STeff(k,r) * selfArvlQlenSeenByClosed(k,r) + STeff(k,sd)*stationaryQlen(k,sd)');
                            end
                        end
                    else
                        switch options.config.multiserver
                            case 'softmin'
                                Wchain(k,r) = STeff(k,r); % high SCV
                                if any(ismember(ocl,r))
                                    Wchain(k,r) = Wchain(k,r) + STeff(k,r) * stationaryQlen(k,r) * Bk(r) + STeff(k,sd) * (stationaryQlen(k,sd) .* Bk(sd))';
                                else
                                    % FCFS approximation + reducing backlog proportionally to server utilizations; somewhat similar to
                                    % Rolia-Sevcik -  method of layers - Sec IV.
                                    switch options.method
                                        case {'default', 'amva.lin', 'lin', 'amva.qdlin','qdlin'} % Linearizer
                                            Wchain(k,r) = Wchain(k,r) + STeff(k,r) * selfArvlQlenSeenByClosed(k,r) * Bk(r) + STeff(k,sd) * (stationaryQlen(k,sd) .* Bk(sd))' + (STeff(k,ccl).*Nchain(ccl)*permute(gamma(r,k,ccl),3:-1:1) - STeff(k,r)*gamma(r,k,r));
                                        otherwise
                                            Wchain(k,r) = Wchain(k,r) + STeff(k,r) * selfArvlQlenSeenByClosed(k,r) * Bk(r) + STeff(k,sd) * (stationaryQlen(k,sd) .* Bk(sd))';
                                    end
                                end
                            case {'default','seidmann'}
                                Wchain(k,r) = STeff(k,r) * (nservers(k)-1); % multi-server correction with serial think time, (1/nservers(k)) term already in STeff
                                Wchain(k,r) = Wchain(k,r) + STeff(k,r); % high SCV
                                if any(ismember(ocl,r))
                                    Wchain(k,r) = Wchain(k,r) + (STeff(k,r) * deltaclass(r) * stationaryQlen(k,r)*Bk(r) + STeff(k,sd).*Bk(sd)*stationaryQlen(k,sd)');
                                else
                                    % FCFS approximation + reducing backlog proportionally to server utilizations; somewhat similar to
                                    % Rolia-Sevcik -  method of layers - Sec IV. (1/nservers(k)) term already in STeff
                                    switch options.method
                                        case {'default', 'amva.lin', 'lin', 'amva.qdlin','qdlin'} % Linearizer
                                            Wchain(k,r) = Wchain(k,r) + (STeff(k,r) * selfArvlQlenSeenByClosed(k,r)*Bk(r) + STeff(k,sd).*Bk(sd)*stationaryQlen(k,sd)') + (STeff(k,ccl).*Nchain(ccl)*permute(gamma(r,k,ccl),3:-1:1) - STeff(k,r)*gamma(r,k,r));
                                        otherwise
                                            Wchain(k,r) = Wchain(k,r) + (STeff(k,r) * selfArvlQlenSeenByClosed(k,r)*Bk(r) + STeff(k,sd).*Bk(sd)*stationaryQlen(k,sd)');
                                    end
                                end
                        end
                    end
                end
                
            case {SchedStrategy.ID_HOL} % non-preemptive priority
                if STeff(k,r) > 0
                    
                    switch options.config.np_priority
                        case {'default','cl'} % Chandy-Lakshmi
                            UHigherPrio=0;
                            for h=nnzclasses_hprio{r}
                                UHigherPrio = UHigherPrio + Vchain(k,h)*STeff(k,h)*(Xchain(h)-Qchain(k,h)*tau(h));
                            end
                            prioScaling = min([max([options.tol,1-UHigherPrio]),1-options.tol]);
                        case 'shadow' % Sevcik's shadow server
                            UHigherPrio=0;
                            for h=nnzclasses_hprio{r}
                                UHigherPrio = UHigherPrio + Vchain(k,h)*STeff(k,h)*Xchain(h);
                            end
                            prioScaling = min([max([options.tol,1-UHigherPrio]),1-options.tol]);
                    end
                    
                    if nservers(k)>1
                        if sum(deltaclass .* Xchain .* Vchain(k,:) .* STeff(k,:)) < 0.75 % light-load case
                            switch options.config.multiserver
                                case 'softmin'
                                    Bk = ((deltaclass .* Xchain .* Vchain(k,:) .* STeff(k,:))); % note: this is in 0-1 as a utilization
                                case {'default','seidmann'}
                                    Bk = ((deltaclass .* Xchain .* Vchain(k,:) .* STeff(k,:)) / nservers(k)); % note: this is in 0-1 as a utilization
                            end
                        else % high-load case
                            switch options.config.multiserver
                                case 'softmin'
                                    Bk = (deltaclass .* Xchain .* Vchain(k,:) .* STeff(k,:)).^nservers(k); % Rolia
                                case {'default','seidmann'}
                                    Bk = (deltaclass .* Xchain .* Vchain(k,:) .* STeff(k,:) / nservers(k)).^nservers(k); % Rolia
                            end
                        end
                    else
                        Bk = ones(1,K);
                    end
                    
                    if nservers(k)==1 && (~isempty(lldscaling) || ~isempty(cdscaling))
                        switch options.config.highvar % high SCV
                            case 'hvmva'
                                Wchain(k,r) = (STeff(k,r) / prioScaling) * (1-sum(Uchain_r(k,ccl)));
                                for s=ccl
                                    UHigherPrio_s=0;
                                    for h=nnzclasses_hprio{s}
                                        UHigherPrio_s = UHigherPrio_s + Vchain(k,h)*STeff(k,h)*(Xchain(h)-Qchain(k,h)*tau(h));
                                    end
                                    prioScaling_s = min([max([options.tol,1-UHigherPrio_s]),1-options.tol]);                                    
                                    Wchain(k,r) = Wchain(k,r) + (STeff(k,s) / prioScaling_s) * Uchain_r(k,s) * (1 + SCVchain(k,s))/2; % high SCV
                                end
                            otherwise % default
                                Wchain(k,r) = STeff(k,r) / prioScaling;
                        end
                        
                        if any(ismember(ocl,r))
                            Wchain(k,r) = Wchain(k,r) + (STeff(k,r) * stationaryQlen(k,r)) / prioScaling;
                        else
                            switch options.method
                                case {'default', 'amva.lin', 'lin', 'amva.qdlin','qdlin'} % Linearizer
                                    %Wchain(k,r) = Wchain(k,r) + (STeff(k,r) * selfArvlQlenSeenByClosed(k,r) + STeff(k,sdprio)*stationaryQlen(k,sdprio)') + (STeff(k,[r,sdprio]).*Nchain([r,sdprio])*permute(gamma(r,k,[r,sdprio]),3:-1:1) - STeff(k,r)*gamma(r,k,r));
                                    Wchain(k,r) = Wchain(k,r) + (STeff(k,r) * selfArvlQlenSeenByClosed(k,r) - STeff(k,r)*gamma(r,k,r)) / prioScaling;
                                otherwise
                                    %Wchain(k,r) = Wchain(k,r) + (STeff(k,r) * selfArvlQlenSeenByClosed(k,r) + STeff(k,sdprio)*stationaryQlen(k,sdprio)');
                                    Wchain(k,r) = Wchain(k,r) + (STeff(k,r) * selfArvlQlenSeenByClosed(k,r)) / prioScaling;
                            end
                        end
                    else
                        switch options.config.multiserver
                            case 'softmin'
                                Wchain(k,r) = STeff(k,r) / prioScaling; % high SCV
                                if any(ismember(ocl,r))
                                    Wchain(k,r) = Wchain(k,r) + STeff(k,r) * stationaryQlen(k,r) * Bk(r) / prioScaling;
                                else
                                    % FCFS approximation + reducing backlog proportionally to server utilizations; somewhat similar to
                                    % Rolia-Sevcik -  method of layers - Sec IV.
                                    switch options.method
                                        case {'default', 'amva.lin', 'lin', 'amva.qdlin','qdlin'} % Linearizer
                                            %Wchain(k,r) = Wchain(k,r) + STeff(k,r) * selfArvlQlenSeenByClosed(k,r) * Bk(r) + STeff(k,sdprio) * (stationaryQlen(k,sdprio) .* Bk(sdprio))' + (STeff(k,[r,sdprio]).*Nchain([r,sdprio])*permute(gamma(r,k,[r,sdprio]),3:-1:1) - STeff(k,r)*gamma(r,k,r));
                                            Wchain(k,r) = Wchain(k,r) + STeff(k,r) * selfArvlQlenSeenByClosed(k,r) * Bk(r) / prioScaling + (STeff(k,[r]).*Nchain([r])*permute(gamma(r,k,[r]),3:-1:1) - STeff(k,r)*gamma(r,k,r)) / prioScaling;
                                        otherwise
                                            %Wchain(k,r) = Wchain(k,r) + STeff(k,r) * selfArvlQlenSeenByClosed(k,r) * Bk(r) + STeff(k,sdprio) * (stationaryQlen(k,sdprio) .* Bk(sdprio))';
                                            Wchain(k,r) = Wchain(k,r) + STeff(k,r) * selfArvlQlenSeenByClosed(k,r) * Bk(r) / prioScaling;
                                    end
                                end
                            case {'default','seidmann'}
                                Wchain(k,r) = STeff(k,r) * (nservers(k)-1)/prioScaling; % multi-server correction with serial think time, (1/nservers(k)) term already in STeff
                                Wchain(k,r) = Wchain(k,r) + STeff(k,r)/prioScaling; % high SCV
                                if any(ismember(ocl,r))
                                    %Wchain(k,r) = Wchain(k,r) + (STeff(k,r) * stationaryQlen(k,r)*Bk(r) + STeff(k,sdprio).*Bk(sdprio)*stationaryQlen(k,sdprio)');
                                    Wchain(k,r) = Wchain(k,r) + (STeff(k,r) * stationaryQlen(k,r)*Bk(r))/prioScaling;
                                else
                                    % FCFS approximation + reducing backlog proportionally to server utilizations; somewhat similar to
                                    % Rolia-Sevcik -  method of layers - Sec IV. (1/nservers(k)) term already in STeff
                                    switch options.method
                                        case {'default', 'amva.lin', 'lin', 'amva.qdlin','qdlin'} % Linearizer
                                            %Wchain(k,r) = Wchain(k,r) + (STeff(k,r) * selfArvlQlenSeenByClosed(k,r)*Bk(r) + STeff(k,sdprio).*Bk(sdprio)*stationaryQlen(k,sdprio)') + (STeff(k,[r,sdprio]).*Nchain([r,sdprio])*permute(gamma(r,k,[r,sdprio]),3:-1:1) - STeff(k,r)*gamma(r,k,r));
                                            Wchain(k,r) = Wchain(k,r) + STeff(k,r) * selfArvlQlenSeenByClosed(k,r)*Bk(r)/prioScaling + (STeff(k,r).*Nchain(r)*permute(gamma(r,k,r),3:-1:1) - STeff(k,r)*gamma(r,k,r))/prioScaling;
                                        otherwise
                                            %Wchain(k,r) = Wchain(k,r) + (STeff(k,r) * selfArvlQlenSeenByClosed(k,r)*Bk(r) + STeff(k,sdprio).*Bk(sdprio)*stationaryQlen(k,sdprio)');
                                            Wchain(k,r) = Wchain(k,r) + STeff(k,r) * selfArvlQlenSeenByClosed(k,r)*Bk(r)/prioScaling;
                                    end
                                end
                        end
                    end
                end
                
        end
    end
end
end