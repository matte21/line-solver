function [Q,U,R,T,C,X,lG,runtime,iter] = solver_mva_analyzer(sn, options)
% [Q,U,R,T,C,X,LG,RUNTIME] = SOLVER_MVA_ANALYZER(QN, OPTIONS)

% Copyright (c) 2012-2022, Imperial College London
% All rights reserved.

iter = NaN;
Tstart = tic;
switch options.method
    case {'exact','mva'}
        [Q,U,R,T,C,X,lG] = solver_mva(sn, options);
    case {'qna'}
        line_warning(mfilename,'QNA implementation is still in beta.')
        [Q,U,R,T,C,X] = solver_qna(sn, options);
        lG = NaN;
    case {'default','amva','bs','qd','qli','fli','aql','qdaql','lin','qdlin'}
        [Q,U,R,T,C,X,lG,iter] = solver_amva(sn, options);
    otherwise
        line_error(mfilename,'Unsupported SolverMVA method.');
end
runtime = toc(Tstart);

if options.verbose
    %line_printf('\nMVA analysis completed. Runtime: %f seconds.\n',runtime);
end

end
