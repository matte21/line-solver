function bool = snHasMultiClassFCFS(qn)
% BOOL = SNHASMULTICLASSFCFS()

i = find(qn.schedid == SchedStrategy.ID_FCFS);
if i > 0
    bool = range([qn.rates(i,:)])>0;
else
    bool = false;
end
end