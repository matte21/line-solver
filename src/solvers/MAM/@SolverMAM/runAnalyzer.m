function runtime = runAnalyzer(self, options)
% RUNTIME = RUN()
% Run the solver

T0=tic;
if nargin<2
    options = self.getOptions;
end


if self.enableChecks && ~self.supports(self.model)
    line_warning(mfilename,'This model contains features not supported by the solver.');
    ME = MException('Line:FeatureNotSupportedBySolver', 'This model contains features not supported by the solver.');
    throw(ME);
end

Solver.resetRandomGeneratorSeed(options.seed);

sn = getStruct(self); 

[Q,U,R,T,C,X] = solver_mam_analyzer(sn, options);

runtime=toc(T0);
self.setAvgResults(Q,U,R,T,C,X,runtime);
end