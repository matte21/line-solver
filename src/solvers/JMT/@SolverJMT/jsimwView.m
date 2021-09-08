function jsimwView(self, options)
% JSIMWVIEW(OPTIONS)

% Copyright (c) 2012-2021, Imperial College London
% All rights reserved.

if self.enableChecks && ~self.supports(self.model)
    ME = MException('Line:FeatureNotSupportedBySolver', 'This model contains features not supported by the solver.');
    throw(ME);
end

if nargin<2
    options=self.options;
end
if options.samples< 5e3
    line_warning(mfilename,'JMT requires at least 5000 samples for each metric. Setting the samples to 5000.\n');
    options.samples = 5e3;
end
self.seed = options.seed;
self.maxSamples = options.samples;
sn = self.getStruct;
writeJSIM(self, sn);
%            if options.verbose
fileName = [getFilePath(self),'jsim',filesep, getFileName(self), '.jsim'];
line_printf('\nJMT Model: %s',fileName);
jsimwView(fileName);
end
