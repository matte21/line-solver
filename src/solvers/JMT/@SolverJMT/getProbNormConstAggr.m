function lNormConst = getProbNormConstAggr(self)
% LNORMCONST = GETPROBNORMCONST()

switch self.options.method
    case {'jmva','jmva.recal','jmva.comom','jmva.ls'}
        self.run();
        lNormConst = self.result.Prob.logNormConstAggr;
    otherwise
        lNormConst = NaN; %#ok<NASGU>
        error('Selected solver method does not compute normalizing constants. Choose either jmva.recal, jmva.comom, or jmva.ls.');
end
end