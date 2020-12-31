function Pr = getProbAggr(self, node, state_a)
% PR = GETPROBSTATEAGGR(NODE, STATE_A)

qn = self.getStruct;
if ~exist('state_a','var')
    state_a = qn.state{qn.nodeToStation(node.index)};
end
stationStateAggr = self.sampleAggr(node);
rows = findrows(stationStateAggr.state, state_a);
t = stationStateAggr.t;
dt = [diff(t);0];
Pr = sum(dt(rows))/sum(dt);
end