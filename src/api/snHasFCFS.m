function bool = snHasFCFS(qn)
% BOOL = HASFCFS()

bool = any(qn.schedid==SchedStrategy.ID_FCFS);
end