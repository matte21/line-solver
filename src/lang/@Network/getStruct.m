function qn = getStruct(self, wantInitialState)
% QN = GETSTRUCT(WANTINITSTATE)
if isempty(self.qn)
    refreshStruct(self);
end
if nargin == 1 || wantInitialState
    [s0, s0prior] = self.getState;
    self.qn.state = s0;
    self.qn.stateprior = s0prior;
end
qn = self.qn;
end
