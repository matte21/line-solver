function [initialState, priorInitialState] = getState(self) % get initial state
% [INITIALSTATE, PRIORINITIALSTATE] = GETSTATE() % GET INITIAL STATE

if ~self.hasInitState
    self.initDefault;
end
initialState = {};
priorInitialState = {};
for ind=1:length(self.nodes)
    if self.nodes{ind}.isStateful
        initialState{end+1,1} = self.nodes{ind}.getState();
        priorInitialState{end+1,1} = self.nodes{ind}.getStatePrior();
    end
end
end