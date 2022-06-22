function bool = snHasMultiClassHeterFCFS(sn)
% BOOL = SNHASMULTICLASSHETERFCFS()

iset = find(sn.schedid == SchedStrategy.ID_FCFS);
bool = true;
for i=iset(:)'
    bool = bool & range([sn.rates(i,:)])>0;
end
end