function [isvalid] = snIsStateValid(qn)
% [ISVALID] = ISSTATEVALID()
nir = [];
sir = [];
for ist=1:qn.nstations
    isf = qn.stationToStateful(ist);
    if size(qn.state{isf},1)>1
        line_warning(mfilename,sprintf('isStateValid will ignore some node %d states, define a unique initial state to address this problem.',ist));
        qn.state{isf} = qn.state{isf}(1,:);
    end
    [~, nir(ist,:), sir(ist,:), ~] = State.toMarginal(qn, qn.stationToNode(ist), qn.state{isf});
end
isvalid = State.isValid(qn, nir, sir);
end