function bool = snHasGPS(qn)
% BOOL = HASGPS()

bool = any(qn.schedid==SchedStrategy.ID_GPS);
end