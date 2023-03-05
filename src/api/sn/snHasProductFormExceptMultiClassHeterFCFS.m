function bool = snHasProductFormExceptMultiClassHeterFCFS(sn)
% BOOL = HASPRODUCTFORMEXCEPTMULTICLASSHETERFCFS()

bool = all(sn.schedid==SchedStrategy.ID_INF | sn.schedid==SchedStrategy.ID_PS | sn.schedid==SchedStrategy.ID_FCFS | sn.schedid==SchedStrategy.ID_LCFSPR);
bool = bool & ~snHasPriorities(sn);
bool = bool & ~snHasForkJoin(sn);
end