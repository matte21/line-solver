function RD = getTranCdfPassT(self, R)
% RD = GETTRANCDFPASST(R)

T0 = tic;
if nargin<2 %~exist('R','var')
    R = self.getAvgRespTHandles;
end
qn = self.getStruct;
[s0, s0prior] = qn.state;
for ind=1:qn.nnodes
    if qn.isstateful(ind)
        isf = QN.nodeToStateful(ind);
        if nnz(s0prior{isf})>1
            line_error(mfilename,'getTranCdfPassT: multiple initial states have non-zero prior - unsupported.');
        end
        qn.state{isf} = s0{isf}(1,:); % assign initial state to network
    end
end
options = self.getOptions;
[odeStateVec] = solver_fluid_initsol(qn, options);
options.init_sol = odeStateVec;
RD = solver_fluid_passage_time(qn, options);
runtime = toc(T0);
self.setDistribResults(RD, runtime);
end