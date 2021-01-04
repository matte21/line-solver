function [ni, nir, sir, kir] = snInitToMarginal(qn)
% [NI, NIR, SIR, KIR] = INITTOMARGINAL()

ni = {}; nir = {}; sir = {}; kir = {};
for ist=1:qn.nstations
    if ~isempty(qn.state{ist})
        [ni{ist,1}, nir{ist,1}, sir{ist,1}, kir{ist,1}] = State.toMarginal(qn,qn.stationToNode(ist),state);
    end
end
end