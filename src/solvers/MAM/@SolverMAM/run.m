function runtime = run(self, options)
% RUNTIME = RUN()
% Run the solver

T0=tic;
if ~exist('options','var')
    options = self.getOptions;
end


if ~self.supports(self.model)
    %                if options.verbose
    error('Line:FeatureNotSupportedBySolver','This model contains features not supported by the solver.');
    %                end
    %                runtime = toc(T0);
    %                return
end

Solver.resetRandomGeneratorSeed(options.seed);

[qn] = self.model.getStruct();

[Q,U,R,T,C,X] = solver_mam_analysis(qn, options);

runtime=toc(T0);
self.setAvgResults(Q,U,R,T,C,X,runtime);
end