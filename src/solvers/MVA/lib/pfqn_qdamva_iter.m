function [Wchain] = pfqn_qdamva_iter(sn, Qchain, Xchain, Uchain, STchain, Vchain, Nchain, SCVchain, options)

M = sn.nstations;
K = sn.nchains;
nservers = sn.nservers;
schedparam = sn.schedparam;
lldscaling = sn.lldscaling;
cdscaling = sn.cdscaling;

Wchain = zeros(M,K);
Uhiprio = zeros(M,K); % utilization due to "permanent jobs" in DPS

Nt = sum(Nchain(isfinite(Nchain)));
delta  = (Nt - 1) / Nt;
deltaclass = (Nchain - 1) ./ Nchain;
deltaclass(isinf(Nchain)) = 1;

nnzclasses = find(Nchain>0);
ocl = find(isinf(Nchain));
ccl = find(isfinite(Nchain) & Nchain>0);

%% evaluate lld and cd correction factors
totArvlQlenSeenByOpen = zeros(M,1);
interpTotArvlQlen = zeros(M,1);
totArvlQlenSeenByClosed = zeros(M,K);
selfArvlQlenSeenByOpen = zeros(M,K);
selfArvlQlenSeenByClosed = zeros(M,K);

for k=1:M
    totArvlQlenSeenByOpen(k) = sum(Qchain(k,nnzclasses));
    interpTotArvlQlen(k) = delta * sum(Qchain(k,nnzclasses));
    for r = nnzclasses
        totArvlQlenSeenByClosed(k,r) = deltaclass(r) * Qchain(k,r) + sum(Qchain(k,setdiff(nnzclasses,r)));
        selfArvlQlenSeenByOpen(k,r) = Qchain(k,r); % qlen of same class as arriving one
        selfArvlQlenSeenByClosed(k,r) = deltaclass(r) * Qchain(k,r); % qlen of same class as arriving one
    end
end

if ~isempty(lldscaling) || ~isempty(cdscaling)
    qdterm = pfqn_qdfun(1 + interpTotArvlQlen, lldscaling, nservers); % qd-amva queue-dependence term, for open we use the closed term anyway as an approximation
    for r=nnzclasses
        cdterm = ones(M,K);
        if isfinite(Nchain(r))
            cdterm(:,r) = pfqn_cdfun(1 + selfArvlQlenSeenByClosed, cdscaling); % qd-amva class-dependence term
        else
            cdterm(:,r) = pfqn_cdfun(1 + selfArvlQlenSeenByOpen, cdscaling); % qd-amva class-dependence term
        end
    end
end

STeff = STchain; % effective service time
Wchain = zeros(M,K);
%% compute response times from current queue-lengths
for r=nnzclasses
    sd = setdiff(nnzclasses,r); % change here to add class priorities
    for k=1:M
        if ~isempty(lldscaling) || ~isempty(cdscaling)
            STeff(k,r) = STchain(k,r) * qdterm(k) * cdterm(k,r);
        end
        
        switch sn.schedid(k)
            case SchedStrategy.ID_INF
                Wchain(k,r) = STeff(k,r);
                
            case SchedStrategy.ID_PS
                switch options.method
                    case {'default', 'amva', 'amva.qd', 'qd'}
                        Wchain(k,r) = Wchain(k,r) + STeff(k,r) * (1 + interpTotArvlQlen(k));
                    case {'amva.bs','bs'}
                        Wchain(k,r) = STeff(k,r) * (nservers(k)-1)/nservers(k); % multi-server correction with serial think time
                        if ismember(r,ocl)
                            Wchain(k,r) = Wchain(k,r) + STeff(k,r) * (1/nservers(k)) * (1 + totArvlQlenSeenByOpen(k));
                        else
                            Wchain(k,r) = Wchain(k,r) + STeff(k,r) * (1/nservers(k)) * (1 + totArvlQlenSeenByClosed(k));
                        end
                end
                
            case SchedStrategy.ID_DPS
                weight = schedparam(k,:);
                if nservers(k)>1
                    line_error(mfilename,'Multi-server DPS not supported yet in AMVA solver.')
                else
                    tss=Inf; % time-scale separation threshold, this was originally at 5, presently it is disabled
                    Uhiprio(k,r) = sum(Uchain(k,weight(k,:) > tss*weight(k,r))); % disabled at the moment
                    STeff(k,r) = STeff(k,r) / (1-Uhiprio(k,r));
                    Wchain(k,r) = STeff(k,r) * selfArvlQlenSeenByClosed(k,r);
                    for s=setdiff(sd,r)
                        if weight(s)==weight(r)
                            Wchain(k,r) = Wchain(k,r) + STeff(k,r) * Qchain(k,s);
                        elseif weight(s)/weight(r)<tss
                            Wchain(k,r) = Wchain(k,r) + STeff(k,r) * Qchain(k,s) * weight(s)/weight(r);
                        elseif weight(s)/weight(r)>tss
                            % if there is time-scale separation, do nothing
                            % all is accounted for by 1/(1-Uhiprio)
                        end
                    end
                end
                
            case {SchedStrategy.ID_FCFS, SchedStrategy.ID_SIRO, SchedStrategy.ID_LCFSPR}
                if STeff(k,r) > 0
                    if nservers(k)>1
                        B = ((deltaclass .* Xchain .* Vchain(k,:) .* STeff(k,:)) / nservers(k)); % note: this is in 0-1 as a utilization
                    else
                        B = ones(1,K);
                    end
                    if nservers(k)==1 && (~isempty(lldscaling) || ~isempty(cdscaling))
                        Wchain(k,r) = STeff(k,r) * (1 + SCVchain(k,r))/2; % high SCV
                        Wchain(k,r) = Wchain(k,r) + (STeff(k,r) * deltaclass(r) * Qchain(k,r) + STeff(k,sd)*Qchain(k,sd)');
                    else
                        Wchain(k,r) = STeff(k,r) * (nservers(k)-1)/nservers(k); % multi-server correction with serial think time
                        Wchain(k,r) = Wchain(k,r) + (1/nservers(k)) * STeff(k,r) * (1 + SCVchain(k,r))/2; % high SCV
                        Wchain(k,r) = Wchain(k,r) + (1/nservers(k)) * (STeff(k,r) * deltaclass(r) * Qchain(k,r)/B(r) + (STeff(k,sd)./B(sd)) .* Qchain(k,sd)'); % FCFS approximation + reducing backlog proportionally to server utilizations; somewhat similar to Rolia-Sevcik -  method of layers - Sec IV.
                    end
                end
        end
    end
end

end