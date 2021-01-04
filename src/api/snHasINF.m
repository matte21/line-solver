function bool = snHasINF(qn)
% BOOL = HASINF()

bool = any(qn.schedid==SchedStrategy.ID_INF);
end