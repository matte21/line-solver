function runtime = run(self)
% RUNTIME = RUN()
% Run the solver

T0=tic;
options = self.getOptions;

if self.enableChecks && ~self.supports(self.model)
    %                if options.verbose
    %line_warning(mfilename,'This model contains features not supported by the solver.');
    ME = MException('Line:FeatureNotSupportedBySolver', 'This model contains features not supported by the solver.');
    throw(ME);
    %                end
    %                runtime = toc(T0);
    %                return
end

Solver.resetRandomGeneratorSeed(options.seed);

[sn] = getStruct(self);

[Q,U,R,T,C,X] = solver_lib_analyzer(sn, options);

runtime=toc(T0);
self.setAvgResults(Q,U,R,T,C,X,runtime);
end