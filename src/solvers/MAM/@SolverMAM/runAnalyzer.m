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

[QN,UN,RN,TN,CN,XN] = solver_mam_analyzer(sn, options);
M = sn.nstations;
R = sn.nclasses;
T = getAvgTputHandles(self);
if ~isempty(T)
    AN = zeros(M,R);
    for i=1:M
        for j=1:M
            for k=1:R
                for r=1:R
                    AN(i,k) = AN(i,k) + TN(j,r)*sn.rt((j-1)*R+r, (i-1)*R+k);
                end
            end
        end
    end
end
runtime=toc(T0);
self.setAvgResults(QN,UN,RN,TN,AN,[],CN,XN,runtime);
end