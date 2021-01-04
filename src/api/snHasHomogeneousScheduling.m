function bool = snHasHomogeneousScheduling(qn, strategy)
% BOOL = HASHOMOGENEOUSSCHEDULING(STRATEGY)

bool = length(findstring(qn.sched,strategy)) == qn.nstations;
end