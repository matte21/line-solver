function [Q,U,R,T,C,X,lG,runtime,iter] = solver_nc_analyzer(sn, options)
% [Q,U,R,T,C,X,LG,RUNTIME] = SOLVER_NC_ANALYZER(QN, OPTIONS)

% Copyright (c) 2012-2023, Imperial College London
% All rights reserved.
Tstart = tic;

nservers = sn.nservers;
if max(nservers(nservers<Inf))>1 & any(isinf(sn.njobs)) & strcmpi(options.method,'exact') %#ok<AND2> 
    line_error(mfilename,'NC solver cannot provide exact solutions for open or mixed queueing networks. Remove the ''exact'' option.');
end

[Q,U,R,T,C,X,lG,~,iter] = solver_nc(sn, options);
runtime = toc(Tstart);

end