function [logNormConst] = getProbNormConstAggr(self)
% [LOGNORMCONST] = GETPROBNORMCONST()

self.run();
logNormConst = self.result.Prob.logNormConstAggr;
end