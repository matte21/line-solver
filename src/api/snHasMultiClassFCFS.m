function bool = snHasMultiClassFCFS(sn)
% BOOL = SNHASMULTICLASSFCFS()

i = find(sn.schedid == SchedStrategy.ID_FCFS);
if i > 0
    bool = range([sn.rates(i,:)])>0;
else
    bool = false;
end
end