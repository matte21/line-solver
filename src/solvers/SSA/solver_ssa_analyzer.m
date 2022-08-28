function [QN,UN,RN,TN,CN,XN,runtime,tranSysState,tranSync,sn] = solver_ssa_analyzer(sn, options)
% [QN,UN,RN,TN,CN,XN,RUNTIME,TRANSYSSTATE] = SOLVER_SSA_ANALYZER(QN, OPTIONS)

% Copyright (c) 2012-2022, Imperial College London
% All rights reserved.

Tstart = tic;

sn.space = sn.state; % SSA progressively grows this cell array into the simulated state space
switch options.method
    case {'default','serial','ssa'}
        [XN,UN,QN,RN,TN,CN,tranSysState,tranSync,sn] = solver_ssa_analyzer_serial(sn, options, false);
    case {'serial.hash','serial.hashed','hashed'}
        [XN,UN,QN,RN,TN,CN,tranSysState,tranSync,sn] = solver_ssa_analyzer_serial(sn, options, true);
    case {'para','parallel','para.hash','parallel.hash'}
        if isoctave
            line_error(mfilename,'Parallel SSA is available only under MATLAB.');
        end
        try
        [XN,UN,QN,RN,TN,CN,tranSysState,tranSync,sn] = solver_ssa_analyzer_spmd(sn, options);        
        catch e
            switch e.identifier
                case 'MATLAB:spmd:NoPCT'
                    line_printf('The ssa.%s method requires the Parallel Computing Toolbox that is unavailable on this machine, switching to ssa.serial.',options.method);
                    [XN,UN,QN,RN,TN,CN,tranSysState,tranSync,sn] = solver_ssa_analyzer_serial(sn, options, true);                    
            end
        end
end

runtime = toc(Tstart);
end