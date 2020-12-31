function [stateSpace,nodeStateSpace] = getStateSpace(self)
% [STATESPACE, MARGSTATESPACE] = GETSTATESPACE()

options = self.getOptions;
if options.force
    self.runAnalyzer;
end
if isempty(self.result) || ~isfield(self.result,'space')
    line_warning(mfilename,'The model solution is not available yet or has not been cached. Either solve it or use the ''force'' option to require this is done automatically, e.g., SolverCTMC(model,''force'',true).getStateSpace()');
    stateSpace = [];
    nodeStateSpace = [];
else
    stateSpace = self.result.space;
    shift = 1;
    for i=1:length(self.result.nodeSpace)
        nodeStateSpace{i} = self.result.space(:,shift:(shift+size(self.result.nodeSpace{i},2)-1));
        shift = shift + size(self.result.nodeSpace{i},2);
    end
end
end