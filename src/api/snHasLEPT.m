function bool = snHasLEPT(qn)
% BOOL = HASLEPT()

bool = any(qn.schedid==SchedStrategy.ID_LEPT);
end