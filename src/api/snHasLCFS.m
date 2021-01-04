function bool = snHasLCFS(qn)
% BOOL = HASLCFS()

bool = any(qn.schedid==SchedStrategy.ID_LCFS);
end