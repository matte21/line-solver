function [lGn] = pfqn_nc(L,N,Z,varargin)
% [LGN] = PFQN_NC(L,N,Z,VARARGIN)

options = Solver.parseOptions(varargin,SolverNC.defaultOptions);

% remove empty classes
nnzClasses = find(N);
L = L(:,nnzClasses);
N = N(:,nnzClasses);
Z = Z(:,nnzClasses);
Lsum = sum(L,2);
Lmax = max(L,[],2);
L = L((Lmax./Lsum)>options.tol,:); % remove stations with no demand
LZsum = sum(L,1) + sum(Z,1);
if any(N(LZsum == 0)>0) % if there is a class with jobs but L and Z all zero
    error('The specified model is impossible: no station has positive demands in one of the non-empty classes.');
end
[M,K]=size(L);

% return immediately if degenerate case
if isempty(L) || sum(L(:))<options.tol % all demands are zero
    if isempty(Z) || sum(Z(:))<options.tol
        lGn = 0;
    else
        lGn = - sum(factln(N)) + sum(N.*log(sum(Z,1)));
    end
    return
elseif M==1 && (isempty(Z) || sum(Z(:))<options.tol) % single node and no think time
    lGn = factln(sum(N)) - sum(factln(N)) + sum(N.*log(sum(L,1)));
    return
end

% contribution from jobs that permanently loop at delay
zeroDemandClasses = find(sum(L,1)<options.tol); % all jobs in delay
nonzeroDemandClasses = setdiff(1:K, zeroDemandClasses);
if sum(Z(:),1)<options.tol || isempty(Z)
    lGz = 0;
else
    if isempty(zeroDemandClasses) % for old MATLAB release compatibility
        lGz = 0;
    else
        Nz = N(zeroDemandClasses);
        lGz = - sum(factln(Nz)) + sum(Nz.*log(sum(Z(:,zeroDemandClasses),1)));
    end
end
Lnnzd = L(:,nonzeroDemandClasses);
Nnnzd = N(nonzeroDemandClasses);
Znnzd = Z(:,nonzeroDemandClasses);

lGn = sub_method(Lnnzd, Nnnzd, Znnzd, options);
end

function lG = sub_method(L,N,Z,options)
% LG = SUB_METHOD(L,N,Z,OPTIONS)
[M,R] = size(L);
switch options.method
    case {'ca'}
        [~,lG] = pfqn_ca(L,N,sum(Z,1));
    case {'exact'}
        if M>=R || sum(N)>20
            [~,lG] = pfqn_ca(L,N,sum(Z,1));
        else
            [~,lG] = pfqn_recal(L,N,sum(Z,1));
        end
    case {'default','adaptive'}
        if M>1
            Nstar = (sum(L)+sum(Z,1))/max(L);
            if sum(N)>5*sum(Nstar) && R >= 2
                [~,lG] = pfqn_le(L,N,sum(Z,1));
            elseif R <= 3
                [~,~,~,~,lG] = pfqn_mva(L,N,sum(Z,1));
            else
                if M>R
                    [~,lG] = pfqn_kt(L,N,sum(Z,1));                    
                else
                    [~,lG] = pfqn_le(L,N,sum(Z,1));
                end
            end
        elseif sum(Z,1)==0 % single queue, no delay
            [~,~,~,~,lG] = pfqn_mva(L,N,sum(Z,1));
        else % repairman model
            if N < 10
                [~,lG] = pfqn_recal(L,N,sum(Z,1));
            elseif N < 50 % otherwise numerical issues
                [~,lG] = pfqn_pnc2(L,N,sum(Z,1));
            else % numerical issue
                [~,lG] = pfqn_le(L,N,sum(Z,1));
            end
        end
    case {'sampling'}        
        if M==1
            [~,lG] = pfqn_grm(L,N,sum(Z,1),options.samples);
        elseif M>R
            [~,lG] = pfqn_mci(L,N,sum(Z,1),options.samples,'imci');
        else
            [~,lG] = pfqn_ls(L,N,sum(Z,1),options.samples);
        end
    case {'mmint','pnc2'}
        if size(L,1)>1
            error('The %s method requires a model with a delay and a single queueing station.',options.method);
        end
        [~,lG] = pfqn_pnc2(L,N,sum(Z,1));
    case {'grm'}
        if size(L,1)>1
            error('The %s method requires a model with a delay and a single queueing station.',options.method);
        end
        [~,lG] = pfqn_grm(L,N,sum(Z,1),options.samples);
    case {'pana','panacea','pnc'}
        [~,lG] = pfqn_panacea(L,N,sum(Z,1));
        if isnan(lG)
            warning('Model is not in normal usage, panacea cannot continue.');
        end
    case 'le'
        [~,lG] = pfqn_le(L,N,sum(Z,1));
    case 'kt'
        [~,lG] = pfqn_kt(L,N,sum(Z,1));
    case 'ls'
        [~,lG] = pfqn_ls(L,N,sum(Z,1),options.samples);
    case {'mci','imci'}
        [~,lG] = pfqn_mci(L,N,sum(Z,1),options.samples,'imci');
    case {'mva'}
        [~,~,~,~,lG] = pfqn_mva(L,N,sum(Z,1));
    case 'propfair'
        [~,lG] = pfqn_propfair(L,N,sum(Z,1));
    case {'recal'}
        [~,lG] = pfqn_recal(L,N,sum(Z,1));
    otherwise
        error('Unrecognized method: %s',options.method);
end
return
end
