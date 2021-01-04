function bool = snHasPS(qn)
% BOOL = HASPS()

bool = any(qn.schedid==SchedStrategy.ID_PS);
end