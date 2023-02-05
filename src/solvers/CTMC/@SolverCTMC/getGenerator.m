function [infGen, eventFilt, ev] = getGenerator(self, options)
% [INFGEN, EVENTFILT] = GETGENERATOR()

% [infGen, eventFilt] = getGenerator(self)
% returns the infinitesimal generator of the CTMC and the
% associated filtration for each event

if nargin>1 && islogical(options)
    line_warning(mfilename,'getGenerator(boolean) is now deprecated - remove the boolean argument.');
    options = self.getOptions;
elseif nargin<2 
    options = self.getOptions;
end

sn = self.getStruct;
if isempty(self.result) || ~isfield(self.result,'infGen')
    %line_warning(mfilename,'The model has not been cached. Running SolverCTMC state space generator.');
    [InfGen,StateSpace,StateSpaceAggr,EventFiltration,~,~,sn] = solver_ctmc(sn, options);
    self.result.infGen = InfGen;
    self.result.space = StateSpace;
    self.result.spaceAggr = StateSpaceAggr;
    self.result.nodeSpace = sn.space;
    self.result.eventFilt = EventFiltration;
end
infGen = self.result.infGen;
eventFilt = self.result.eventFilt;
ev = sn.sync;
end
