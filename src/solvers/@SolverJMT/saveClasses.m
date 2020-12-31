function [simElem, simDoc] = saveClasses(self, simElem, simDoc)
% [SIMELEM, SIMDOC] = SAVECLASSES(SIMELEM, SIMDOC)

% Copyright (c) 2012-2021, Imperial College London
% All rights reserved.

qn = self.getStruct;

numOfClasses = qn.nclasses;
for r=1:numOfClasses
    userClass = simDoc.createElement('userClass');
    userClass.setAttribute('name', qn.classnames{r});
    if isinf(qn.njobs(r))
        userClass.setAttribute('type', 'open');
    else
        userClass.setAttribute('type', 'closed');
    end
    userClass.setAttribute('priority', int2str(qn.classprio(r)));
    refStatIndex = qn.refstat(r);
    refNodeIndex = qn.stationToNode(qn.refstat(r));
    refStatName = qn.nodenames{refNodeIndex};
    if ~isempty(qn.proc{refStatIndex,r})
        if isfinite(qn.njobs(r)) % if closed
            userClass.setAttribute('customers', int2str(qn.njobs(r)));
            userClass.setAttribute('referenceSource', refStatName);
        elseif isnan(qn.proc{refStatIndex,r}{1}) % open disabled in source
            userClass.setAttribute('referenceSource', 'ClassSwitch');
        else % if other open
            userClass.setAttribute('referenceSource', qn.nodenames{qn.stationToNode(qn.refstat(r))});
        end
    else
        userClass.setAttribute('referenceSource', qn.nodenames{qn.stationToNode(qn.refstat(r))});
    end
    simElem.appendChild(userClass);
end

end
