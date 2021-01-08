function sn = getStruct(self, wantInitialState)
% QN = GETSTRUCT(WANTINITSTATE)
if isempty(self.sn)
    refreshStruct(self);
end
if nargin == 1 || wantInitialState
    [s0, s0prior] = self.getState;
    self.sn.state = s0;
    self.sn.stateprior = s0prior;
end
sn = self.sn;
end
