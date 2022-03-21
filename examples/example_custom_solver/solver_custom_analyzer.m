function [QN,UN,RN,TN,CN,XN,runtime] = solver_custom_analyzer(sn, options)
% [QN,UN,RN,TN,CN,XN,RUNTIME] = SOLVER_CUSTOM_ANALYZER(QN, OPTIONS)

% Copyright (c) 2012-2022, Imperial College London
% All rights reserved.

Tstart = tic;

[QN,UN,RN,TN,CN,XN] = solver_custom(sn, options);

QN(isnan(QN))=0;
CN(isnan(CN))=0;
RN(isnan(RN))=0;
UN(isnan(UN))=0;
XN(isnan(XN))=0;
TN(isnan(TN))=0;

runtime = toc(Tstart);

if options.verbose
    line_printf('\nSolver Custom analysis completed. Runtime: %f seconds.\n',runtime);
end
end