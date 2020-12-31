function [logNormConst] = getProbNormConstAggr(self)
% [LOGNORMCONST] = GETPROBNORMCONST()

runAnalyzer(self);
logNormConst = self.result.Prob.logNormConstAggr;
end