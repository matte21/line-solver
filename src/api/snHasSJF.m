function bool = snHasSJF(qn)
% BOOL = HASSJF()

bool = any(qn.schedid==SchedStrategy.ID_SJF);
end