function [stateSpace,nodeStateSpace] = getStateSpace(self, options)
% [STATESPACE, MARGSTATESPACE] = GETSTATESPACE()

if nargin<2
    options = self.getOptions;
end
sn = self.getStruct;

if isempty(self.result) || ~isfield(self.result,'space')
    [SS,SSh,qnc] = State.spaceGenerator(sn, options.cutoff, options);
    sn.space = qnc.space;
    if options.verbose
        line_printf('\nCTMC state space size: %d states. ',size(SS,1));
    end
    SSq = zeros(size(SSh));
    nstateful = sn.nstateful;
    nclasses = sn.nclasses;
    A = length(sn.sync);
    % for all synchronizations
    for a=1:A
        stateCell = cell(nstateful,1);
        for s=1:size(SSh,1)
            state = SSh(s,:);
            % update state cell array and SSq
            for ind = 1:sn.nnodes
                if sn.isstateful(ind)
                    isf = sn.nodeToStateful(ind);
                    stateCell{isf} = sn.space{isf}(state(isf),:);
                    if sn.isstation(ind)
                        ist = sn.nodeToStation(ind);
                        [~,nir] = State.toMarginal(sn,ind,stateCell{isf});
                        SSq(s,((ist-1)*nclasses+1):ist*nclasses) = nir;
                    end
                end
            end
        end
    end
    self.result.space = SS;
    self.result.nodeSpace = qnc.space;
end

stateSpace = self.result.space;

shift = 1;
nodeStateSpace = cell(1,length(self.result.nodeSpace));
for i=1:length(self.result.nodeSpace)
    nodeStateSpace{i} = self.result.space(:,shift:(shift+size(self.result.nodeSpace{i},2)-1));
    shift = shift + size(self.result.nodeSpace{i},2);
end
end