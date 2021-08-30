function [Q,U,R,T,C,X,lG,runtime] = solver_mvald_analyzer(sn, options)
% [Q,U,R,T,C,X,RUNTIME] = SOLVER_MVALD_ANALYZER(SN, OPTIONS)

% Copyright (c) 2012-2021, Imperial College London
% All rights reserved.

Tstart = tic;
switch options.method
    case {'exact','mva'}
        if ~isempty(sn.cdscaling)
            line_error(mfilename,'Exact class-dependent solver not available in MVA.');
        end        
        [Q,U,R,T,C,X,lG] = solver_mvald(sn, options);
    case {'default','amva','qd'}
        [Q,U,R,T,C,X,lG] = solver_amva(sn, options);
    otherwise
        line_error(mfilename,sprintf('The %s method is not supported by the load-dependent MVA solver.',options.method));
end

runtime = toc(Tstart);

if options.verbose > 0
    %    line_printf('\nMVA load-dependent analysis completed. Runtime: %f seconds.\n',runtime);
end
return
end
