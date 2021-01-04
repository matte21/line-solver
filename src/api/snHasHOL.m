function bool = snHasHOL(qn)
% BOOL = HASHOL()

bool = any(qn.schedid==SchedStrategy.ID_HOL);
end