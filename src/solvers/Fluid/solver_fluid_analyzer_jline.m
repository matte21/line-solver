function [QN, UN, RN, TN, CN, XN, t, QNt, UNt, TNt, xvec] = solver_fluid_analyzer_jline(network, options)
% [QN, UN, RN, TN, CN, XN, T, QNT, UNT, TNT, XVEC] = SOLVER_FLUID_ANALYZER_JLINE(QN, OPTIONS)

% Copyright (c) 2012-2022, Imperial College London
% All rights reserved.

%%%% Returning Result from JLINE %%%%

jmodel = LINE2JLINE(network);
jsolver = JLINE.SolverFluid(jmodel);
import jline.solvers.fluid.*;

jsolver.options.method = options.method;
result = jsolver.runMethodSpecificAnalyzerViaLine();

%%%% Migrating Result from JLINE SolverResult to native MatLab data structures %%%%

M = jmodel.getNumberOfStatefulNodes; %number of stations
K = jmodel.getNumberOfClasses;    %number of classes

QN = NaN*zeros(M,K);
UN = NaN*zeros(M,K);
RN = NaN*zeros(M,K);
TN = NaN*zeros(M,K);
CN = NaN*zeros(1,K);
XN = NaN*zeros(1,K);

QNt = cell(M,K);
UNt = cell(M,K);
TNt = cell(M,K);

rows = 0;
for i=1:result.t.size()
    rows = rows + result.t.get(i-1).getNumRows();
end
t = NaN*zeros(rows, 1); 

for i=1:M 
    for j=1:K
        QN(i,j) = result.QN.get(i-1, j-1);
        UN(i,j) = result.UN.get(i-1, j-1);
        RN(i,j) = result.RN.get(i-1, j-1);
        TN(i,j) = result.TN.get(i-1, j-1);
    end
end

for j=1:K
    CN(1,j) = result.CN.get(0, j-1);
    XN(1,j) = result.XN.get(0, j-1);
end

Tmax = result.QNt(i,j).getNumRows();
for i=1:M 
    for j=1:K
        for p=1:Tmax
            QNt{i,j}(p,1) = result.QNt(i,j).get(p-1, 0);
            UNt{i,j}(p,1) = result.UNt(i,j).get(p-1, 0);
            TNt{i,j}(p,1) = result.TNt(i,j).get(p-1, 0);
        end
    end
end

nextrow = 1;
for i=1:result.t.size()
    rows = result.t.get(i-1).getNumRows();
    cols = result.t.get(i-1).getNumCols();
    for j=1:rows
        for k = 1:cols
            t(nextrow, 1) = result.t.get(i-1).get(j-1, k-1);
            nextrow = nextrow + 1;
        end
    end
end

iter = result.xvec_it.size();
phases = result.xvec_it.get(iter - 1).getNumCols();
for j=1:phases
    xvec.odeStateVec(1,j) = result.xvec_it.get(iter - 1).get(0, j-1);
end
xvec.sn = network;
end