function [QN,UN,RN,TN,CN,XN] = solver_custom(sn, options)
% [Q,U,R,T,C,X] = SOLVER_CUSTOM(QN, OPTIONS)

% Copyright (c) 2012-2022, Imperial College London
% All rights reserved.

%% generate local state spaces
M = sn.nstations;
K = sn.nclasses;
N = sn.njobs';
rt = sn.rt;
V = sn.visits;

QN = zeros(M,K);
UN = zeros(M,K);
RN = zeros(M,K);
TN = zeros(M,K);
CN = zeros(1,K);
XN = zeros(1,K);

line_error(mfilename,'The solver needs to be implemented here. Returning with no result.');
end