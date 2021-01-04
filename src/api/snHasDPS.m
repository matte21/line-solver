function bool = snHasDPS(qn)
% BOOL = HASDPS()

bool = any(qn.schedid==SchedStrategy.ID_DPS);
end