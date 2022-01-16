function [XN,UN,QN,RN,TN,CN,tranSysState,tranSync]=solver_ssa_analyzer_taussa(network, options, tl_option, tau)
% [XN,UN,QN,RN,TN,CN]=SOLVER_SSA_ANALYZER_SERIAL(SN, OPTIONS)

javaaddpath(which('TauSSA.jar'));
import SimUtil.*; %#ok<SIMPT>
import StochLib.*; %#ok<SIMPT>

[java_network, ssa_solver] = TauSSA_integration.compile_network(network);

M = java_network.getNumberOfStatefulNodes; %number of stations
K = java_network.getNumberOfClasses;    %number of classes

ssa_solver.setOptions().samples = options.samples;
ssa_solver.setOptions().seed = options.seed;

if tl_option == 1
    if tau <= 0
        tau = 1.5/java_network.avgRate;
    end
    ssa_solver.setOptions().configureTauLeap(TauSSA.TauLeapingType(TauSSA.TauLeapingVarType.Poisson, TauSSA.TauLeapingOrderStrategy.DirectedCycle, TauSSA.TauLeapingStateStrategy.Cutoff, tau));
elseif tl_option == 2
    if tau <= 0
        tau = 1.5/java_network.avgRate;
    end
    ssa_solver.setOptions().configureTauLeap(TauSSA.TauLeapingType(TauSSA.TauLeapingVarType.Poisson, TauSSA.TauLeapingOrderStrategy.RandomEvent, TauSSA.TauLeapingStateStrategy.Cutoff, tau));
end

timeline = ssa_solver.solve();

tranSysState = [];
tranSync = [];

XN = NaN*zeros(1,K);
UN = NaN*zeros(M,K);
QN = NaN*zeros(M,K);
RN = NaN*zeros(M,K);
TN = NaN*zeros(M,K);
CN = NaN*zeros(1,K);

for n=1:M
    for m=1:K
        metrics = timeline.getMetrics(n-1, m-1);
        QN(n,m) = metrics.getMetricValueByName("Queue Length");
        UN(n,m) = metrics.getMetricValueByName("Utilization");
        TN(n,m) = metrics.getMetricValueByName("Throughput");
        RN(n,m) = metrics.getMetricValueByName("Response Time");
    end
end

QN(isnan(QN))=0;
CN(isnan(CN))=0;
RN(isnan(RN))=0;
UN(isnan(UN))=0;
XN(isnan(XN))=0;
TN(isnan(TN))=0;
end
