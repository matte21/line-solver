function bool = snHasLJF(qn)
% BOOL = HASLJF()

bool = any(qn.schedid==SchedStrategy.ID_LJF);
end