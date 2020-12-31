function [infGen, eventFilt, ev] = getGenerator(self, force)
% [INFGEN, EVENTFILT] = GETGENERATOR()

% [infGen, eventFilt] = getGenerator(self)
% returns the infinitesimal generator of the CTMC and the
% associated filtration for each event

if nargin==1
    force=false;
end
options = self.getOptions;
if options.force || force
    self.runAnalyzer;
end
if isempty(self.result) || ~isfield(self.result,'infGen')
    line_warning(mfilename,'The model has not been cached. Either solve it, set options.force=true or call getGenerator(true).');
    infGen = [];
    eventFilt = [];
else
    infGen = self.result.infGen;
    eventFilt = self.result.eventFilt;
end
ev = self.getStruct.sync;
end

tstate = sampleSys(self, numevents);
sampleAggr = sampleAggr(self, node, numSamples);

end