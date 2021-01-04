function bool = snHasSEPT(qn)
% BOOL = HASSEPT()

bool = any(qn.schedid==SchedStrategy.ID_SEPT);
end