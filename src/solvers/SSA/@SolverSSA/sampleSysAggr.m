function tranSysState = sampleSysAggr(self, numSamples)
% TRANSYSSTATEAGGR = sampleSysAggr(NUMSAMPLES)
options = self.getOptions;

if nargin<2 %~exist('numSamples','var')
    numSamples = options.samples;
end

switch options.method
    case {'default','serial'}
        options.samples = numSamples;
        options.force = true;
        sn = self.getStruct;
        
        [~, tranSystemState, tranSync] = self.runAnalyzer(options);
        tranSysState = struct();
        tranSysState.handle = self.model.getStatefulNodes';
        tranSysState.t = tranSystemState{1};
        tranSysState.state = {tranSystemState{2:end}};
        tranSysState.event = tranSync;
        event = tranSync;
                
        for isf=1:sn.nstateful
            if size(tranSysState.state{isf},1) > numSamples
                tranSysState.t = tranSystemState(1:numSamples);
                tranSysState.state{isf} = tranSysState.state{isf}(1:numSamples,:);
            end
            [~,tranSysState.state{isf}] = State.toMarginal(sn,sn.statefulToNode(isf),tranSysState.state{isf});
        end
        
        sn = self.getStruct;
        tranSysState.event = {};
        for e = 1:length(event)
            for a=1:length(sn.sync{event(e)}.active)
                tranSysState.event{end+1} = sn.sync{event(e)}.active{a};
                tranSysState.event{end}.t = tranSysState.t(e);
            end
            for p=1:length(sn.sync{event(e)}.passive)
                tranSysState.event{end+1} = sn.sync{event(e)}.passive{p};
                tranSysState.event{end}.t = tranSysState.t(e);
            end
        end
        tranSysState.isaggregate = true;
    otherwise
        line_error(mfilename,'sampleSys is not available in SolverSSA with the chosen method.');
end
end