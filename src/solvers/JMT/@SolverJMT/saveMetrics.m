function [simElem, simDoc] = saveMetrics(self, simElem, simDoc)
% [SIMELEM, SIMDOC] = SAVEMETRICS(SIMELEM, SIMDOC)

% Copyright (c) 2012-2022, Imperial College London
% All rights reserved.

handles = self.model.handles;
[simElem, simDoc] = saveMetric(self, simElem, simDoc, handles.Q);
[simElem, simDoc] = saveMetric(self, simElem, simDoc, handles.U);
[simElem, simDoc] = saveMetric(self, simElem, simDoc, handles.R);
[simElem, simDoc] = saveMetric(self, simElem, simDoc, handles.T);
%[simElem, simDoc] = saveMetric(simElem, simDoc, handles.A); % not supported by JMT
end


