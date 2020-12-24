function qn = getStruct(self, wantInitialState)
% QN = GETSTRUCT(WANTINITSTATE)
if isempty(self.qn)
    self.refreshStruct();
end
if nargin == 1 || wantInitialState
    self.qn.state = self.getState;
end
qn = self.qn.copy;
end
