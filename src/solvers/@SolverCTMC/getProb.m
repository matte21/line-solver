function Pnir = getProb(self, node, state)
% PNIR = GETPROB(NODE, STATE)

if ~exist('node','var')
    line_error(mfilename,'getProb requires to pass a parameter the station of interest.');
end
if ~isfield(self.options,'keep')
    self.options.keep = false;
end
T0 = tic;
qn = self.getStruct;
qn.state = qn.state;
if exist('state','var')
    qn.state{node} = state;
end
ind = node.index;
for isf=1:length(qn.state)
    isf_param = qn.nodeToStateful(ind);
    if isf ~= isf_param
        qn.state{isf} = qn.state{isf}*0 -1;
    end
end
Pnir = solver_ctmc_marg(qn, self.options);
self.result.('solver') = getName(self);
self.result.Prob.marginal = Pnir;
runtime = toc(T0);
self.result.runtime = runtime;
Pnir = Pnir(node);
end