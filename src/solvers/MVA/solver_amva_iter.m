function [Wchain, STeff] = solver_amva_iter(sn, Qchain, Xchain, Uchain, STchain, Vchain, Nchain, SCVchain, options)

M = sn.nstations;
K = sn.nchains;
nservers = sn.nservers;
schedparam = sn.schedparam;
lldscaling = sn.lldscaling;
cdscaling = sn.cdscaling;

Wchain = zeros(M,K);
Uhiprio = zeros(M,K); % utilization due to "permanent jobs" in DPS

Nt = sum(Nchain(isfinite(Nchain)));
if all(isinf(Nchain))
    delta = 1;
else
    delta = (Nt - 1) / Nt;
end
deltaclass = (Nchain - 1) ./ Nchain;
deltaclass(isinf(Nchain)) = 1;

nnzclasses = find(Nchain>0);
ocl = find(isinf(Nchain));
%ccl = find(isfinite(Nchain) & Nchain>0);

%% evaluate lld and cd correction factors
totArvlQlenSeenByOpen = zeros(M,1);
interpTotArvlQlen = zeros(M,1);
totArvlQlenSeenByClosed = zeros(M,K);
stationaryQlen = zeros(M,K);
selfArvlQlenSeenByClosed = zeros(M,K);
for k=1:M
    totArvlQlenSeenByOpen(k) = sum(Qchain(k,nnzclasses));
    interpTotArvlQlen(k) = delta * sum(Qchain(k,nnzclasses));
    for r = nnzclasses
        selfArvlQlenSeenByClosed(k,r) = deltaclass(r) * Qchain(k,r); % qlen of same class as arriving one
        totArvlQlenSeenByClosed(k,r) = deltaclass(r) * Qchain(k,r) + sum(Qchain(k,setdiff(nnzclasses,r)));
        stationaryQlen(k,r) = Qchain(k,r); % qlen of same class as arriving one
    end
end

%% all methods use LLD and CD corrections from QD-AMVA
if isempty(lldscaling)
    lldscaling = ones(M,Nt);
end
lldterm = pfqn_lldfun(1 + interpTotArvlQlen, lldscaling);

cdterm = ones(M,K);
for r=nnzclasses
    if isfinite(Nchain(r))
        cdterm(:,r) = pfqn_cdfun(1 + selfArvlQlenSeenByClosed, cdscaling); % qd-amva class-dependence term
    else
        cdterm(:,r) = pfqn_cdfun(1 + stationaryQlen, cdscaling); % qd-amva class-dependence term
    end
end

switch options.config.multiserver
    case 'softmin'
        msterm = pfqn_lldfun(1 + interpTotArvlQlen, [], nservers); % if native qd then account for multiserver in the correciton terms
    case 'seidmann'
        msterm = ones(M,1) ./ nservers(:);
        msterm(msterm==0) = 1; % infinite server case
    case 'default'
        msterm = pfqn_lldfun(1 + interpTotArvlQlen, [], nservers); % if native qd then account for multiserver in the correciton terms
        fcfsset = sn.schedid==SchedStrategy.ID_FCFS;
        msterm(fcfsset) = 1 / nservers(fcfsset);
    otherwise
        line_error(mfilename,'Unrecognize multiserver approximation method');
end

Wchain = zeros(M,K);

STeff = STchain; % effective service time
for r=nnzclasses
    for k=1:M
        STeff(k,r) = STchain(k,r) * lldterm(k) * msterm(k) * cdterm(k,r);
    end
end

%% if amva.qli, update now totArvlQlenSeenByClosed with STeff
switch options.method
    case {'amva.qli','qli'} % Wang-Sevcik queue line
        infset = sn.schedid == SchedStrategy.ID_INF;
        for k=1:M
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
    case {'amva.fli','fli'} % Wang-Sevcik fraction line
        infset = sn.schedid == SchedStrategy.ID_INF;
        for k=1:M
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

%% compute response times from current queue-lengths
for r=nnzclasses
    sd = setdiff(nnzclasses,r); % change here to add class priorities
    for k=1:M
        
        switch sn.schedid(k)
            case SchedStrategy.ID_INF
                Wchain(k,r) = STeff(k,r);
                
            case SchedStrategy.ID_PS
                switch options.method
                    case {'default', 'amva', 'amva.qd', 'qd'} % QD-AMVA interpolation
                        switch options.config.multiserver
                            case 'seidmann' % in this case, qd handles only lld and cd scalings
                                Wchain(k,r) = STeff(k,r) * (nservers(k)-1); % multi-server correction with serial think time, (1/nservers(k)) term already in STeff
                                if ismember(r,ocl)
                                    Wchain(k,r) = Wchain(k,r) + STeff(k,r) * (1/nservers(k)) * (1 + totArvlQlenSeenByOpen(k));
                                else
                                    Wchain(k,r) = Wchain(k,r) + STeff(k,r) * (1/nservers(k)) * (1 + interpTotArvlQlen(k));
                                end
                            case {'default','softmin'}
                                if ismember(r,ocl)
                                    Wchain(k,r) = STeff(k,r) * (1 + totArvlQlenSeenByOpen(k));
                                else
                                    Wchain(k,r) = STeff(k,r) * (1 + interpTotArvlQlen(k));
                                end
                        end
                    otherwise % Bard-Schweitzer interpolation and Wang-Sevcik algorithms
                        switch options.config.multiserver
                            case 'seidmann'
                                Wchain(k,r) = STeff(k,r) * (nservers(k)-1); % multi-server correction with serial think time, (1/nservers(k)) term already in STeff
                                if ismember(r,ocl)
                                    Wchain(k,r) = Wchain(k,r) + STeff(k,r) * (1 + totArvlQlenSeenByOpen(k));
                                else
                                    Wchain(k,r) = Wchain(k,r) + STeff(k,r) * (1 + totArvlQlenSeenByClosed(k));
                                end
                            case {'default','softmin'}
                                if ismember(r,ocl)
                                    Wchain(k,r) = Wchain(k,r) + STeff(k,r) * (1 + totArvlQlenSeenByOpen(k));
                                else
                                    Wchain(k,r) = Wchain(k,r) + STeff(k,r) * (1 + totArvlQlenSeenByClosed(k));
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
                    for s=setdiff(sd,r) % slowdown due to classes s!=r
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
                        Wchain(k,r) = STeff(k,r) * lldterm(k) * cdterm(k,r) * (1 + SCVchain(k,r))/2; % high SCV
                        if ismember(ocl,r)
                            Wchain(k,r) = Wchain(k,r) + (STeff(k,r) * stationaryQlen(k,r) + STeff(k,sd)*stationaryQlen(k,sd)');
                        else
                            Wchain(k,r) = Wchain(k,r) + (STeff(k,r) * selfArvlQlenSeenByClosed(k,r) + STeff(k,sd)*stationaryQlen(k,sd)');
                        end
                    else
                        switch options.config.multiserver
                            case 'softmin'
                                Wchain(k,r) = STchain(k,r) * lldterm(k) * cdterm(k,r) * (1 + SCVchain(k,r))/2; % high SCV
                                if ismember(ocl,r)
                                    Wchain(k,r) = Wchain(k,r) + STeff(k,r) * stationaryQlen(k,r) * Bk(r) + STeff(k,sd) * (stationaryQlen(k,sd) .* Bk(sd))';
                                else
                                    % FCFS approximation + reducing backlog proportionally to server utilizations; somewhat similar to
                                    % Rolia-Sevcik -  method of layers - Sec IV.
                                    Wchain(k,r) = Wchain(k,r) + STeff(k,r) * selfArvlQlenSeenByClosed(k,r) * Bk(r) + STeff(k,sd) * (stationaryQlen(k,sd) .* Bk(sd))';
                                end
                            case {'default','seidmann'}
                                Wchain(k,r) = STeff(k,r) * (nservers(k)-1); % multi-server correction with serial think time, (1/nservers(k)) term already in STeff
                                Wchain(k,r) = Wchain(k,r) + STeff(k,r) * (1 + SCVchain(k,r))/2; % high SCV
                                if ismember(ocl,r)
                                    Wchain(k,r) = Wchain(k,r) + (STeff(k,r) * deltaclass(r) * stationaryQlen(k,r)*Bk(r) + STeff(k,sd).*Bk(sd)*stationaryQlen(k,sd)');
                                else
                                    % FCFS approximation + reducing backlog proportionally to server utilizations; somewhat similar to
                                    % Rolia-Sevcik -  method of layers - Sec IV. (1/nservers(k)) term already in STeff
                                    Wchain(k,r) = Wchain(k,r) + (STeff(k,r) * selfArvlQlenSeenByClosed(k,r)*Bk(r) + STeff(k,sd).*Bk(sd)*stationaryQlen(k,sd)');
                                end
                        end
                    end
                end
        end
    end
end
end