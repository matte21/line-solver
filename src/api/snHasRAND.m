function bool = snHasRAND(qn)
% BOOL = HASRAND()

bool = any(qn.schedid==SchedStrategy.ID_SIRO);
end