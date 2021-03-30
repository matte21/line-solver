function [Pnir,runtime,fname] = solver_ctmc_joint(sn, options)
% [PNIR,RUNTIME,FNAME] = SOLVER_CTMC_JOINT(QN, OPTIONS)
%
% Copyright (c) 2012-2021, Imperial College London
% All rights reserved.

M = sn.nstations;    %number of stations
K = sn.nclasses;    %number of classes
fname = '';
rt = sn.rt;
Tstart = tic;

myP = cell(K,K);
for k = 1:K
    for c = 1:K
        myP{k,c} = zeros(sn.nstations);
    end
end

for i=1:sn.nstations
    for j=1:sn.nstations
        for k = 1:K
            for c = 1:K
                % routing table for each class
                myP{k,c}(i,j) = rt((i-1)*K+k,(j-1)*K+c);
            end
        end
    end
end

[Q,SS,~,~,~,~,sn] = solver_ctmc(sn, options);
if options.keep
    fname = lineTempName;
    save([fname,'.mat'],'Q','SSq')
    line_printf('\nCTMC generator and state space saved in: ');
    line_printf([fname, '.mat'])
end
pi = ctmc_solve(Q);
pi(pi<1e-14)=0;

statevec = [];
state = sn.state;
for i=1:sn.nstations
    if sn.isstateful(i)
        isf = sn.nodeToStateful(i);
        state_i = [zeros(1,size(sn.space{isf},2)-length(state{isf})),state{isf}];
        statevec = [statevec, state_i];
    end
end
Pnir = pi(findrows(SS, statevec));

runtime = toc(Tstart);

if options.verbose > 0
    line_printf('CTMC analysis completed. Runtime: %f seconds.\n',runtime);
end
end
