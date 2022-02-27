function [CNchain,XNchain] = getAvgSys(self,R,T)
% [CNCHAIN,XNCHAIN] = GETAVGSYS(SELF,R,T)

% Return average system metrics at steady state
%
% Copyright (c) 2012-2022, Imperial College London
% All rights reserved.

sn = self.model.getStruct();
if nargin < 3
    R = self.getAvgRespTHandles;
    T = self.getAvgTputHandles;
end
[~,~,RN,TN] = self.getAvg([],[],R,T);

if self.model.hasJoin
    line_warning(mfilename,'System response time computation not yet supported with join nodes.');
    RN = RN*NaN;
end

refstats = sn.refstat;
completes = true(1,sn.nclasses);
for r=1:sn.nclasses
    completes(r) = T{refstats(r),r}.class.completes;
end

%if any(isinf(sn.njobs')) % if the model has any open class
% TODO: this could be optimised by computing the statistics
% only for open chains

% compute chain visits
alpha = zeros(sn.nstations,sn.nclasses);
CNclass = zeros(1,sn.nclasses);
for c=1:sn.nchains
    inchain = find(sn.chains(c,:));
    for r=inchain
        CNclass(r)=0;
        for i=1:sn.nstations
            if ~isempty(RN) && ~(isinf(sn.njobs(r)) && i==sn.refstat(r)) % not empty and not source
                CNclass(r) = CNclass(r) + sn.visits{c}(i,r)*RN(i,r)/sn.visits{c}(sn.refstat(r),r);
            end
        end
    end
end

for c=1:sn.nchains
    inchain = find(sn.chains(c,:));
    completingclasses = sn.chains(c,:) & completes;
    for i=1:sn.nstations
        if any(intersect(find(sn.refclass), inchain))
            for k=intersect(find(sn.refclass), inchain) % for all classes within the chain (a class belongs to a single chain, the reference station must be identical for all classes within a chain )
                alpha(i,k) = alpha(i,k) + sn.visits{c}(i,k)/sum(sn.visits{c}(sn.refstat(k),completingclasses));
            end
        else
            for k=inchain % for all classes within the chain (a class belongs to a single chain, the reference station must be identical for all classes within a chain )
                alpha(i,k) = alpha(i,k) + sn.visits{c}(i,k)/sum(sn.visits{c}(sn.refstat(k),completingclasses));
            end
        end
    end
end
alpha(~isfinite(alpha))=0;
%end

% compute average chain metrics
CNchain = zeros(1,sn.nchains);
XNchain = zeros(1,sn.nchains);
for c=1:sn.nchains
    inchain = find(sn.chains(c,:));
    completingclasses = find(sn.chains(c,:) & completes);
    if ~isempty(TN)
        XNchain(c) = 0;
        % all classes in same chain must share the same refstation, so we use the first one
        ref = refstats(inchain(1));
        % we now compute the incoming system throughput to the
        % reference station from completing classes
        for i=1:sn.nstations
            for r=completingclasses(:)'
                if any(intersect(find(sn.refclass), inchain))
                    for s=intersect(find(sn.refclass), inchain)
                        if ~isnan(TN(i,r))
                            XNchain(c) = XNchain(c) + sn.rt((i-1)*sn.nclasses + r, (ref-1)*sn.nclasses + s )*TN(i,r);
                        end
                    end
                else
                    for s=inchain(:)'
                        if ~isnan(TN(i,r))
                            XNchain(c) = XNchain(c) + sn.rt((i-1)*sn.nclasses + r, (ref-1)*sn.nclasses + s )*TN(i,r);
                        end
                    end
                end
            end
        end
    end
    
    % If this is a closed chain we simply apply Little's law
    nJobsChain = sum(sn.njobs(find(sn.chains(c,:)))); %#ok<FNDSB>
    %if ~isinf(nJobsChain)
    %    CNchain(c) = nJobsChain / XNchain(c);
    %else % if this is an open chain
    if isinf(nJobsChain)
        if length(inchain) ~= length(completingclasses)
            line_error(mfilename,'Edge-based chain definition not yet supported for open queueing networks.');
            %else
            % we use nan sum to disregard response at stations where
            % the class is not defined
            %    CNchain(c) = sumfinite(alpha(refstats(inchain(1)),inchain).*CNclass(inchain));
        end
    end
    CNchain(c) = sumfinite(alpha(refstats(inchain(1)),inchain).*CNclass(inchain));
end
end
