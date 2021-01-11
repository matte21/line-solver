function jsimgView(self)
% JSIMGVIEW()

[Q,U,R,T,A] = getAvgHandles(self); % create measures
s=SolverJMT(self,Solver.defaultOptions,jmtGetPath); s.jsimgView;
end