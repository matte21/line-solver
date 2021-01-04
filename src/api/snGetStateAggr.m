function [initialStateAggr] = snGetStateAggr(qn) % get initial state
% [INITIALSTATEAGGR] = GETSTATEAGGR() % GET INITIAL STATE

initialState = qn.state;
initialStateAggr = cell(size(initialState));
for isf=1:length(initialStateAggr)
    ind = qn.statefulToNode(isf);
    [~,initialStateAggr{isf}] = State.toMarginalAggr(qn, ind, initialState{isf});
end
end