function plot(self, showTaskGraph)
% PLOT(SELF, SHOWTASKGRAPH)

% Copyright (c) 2012-2023, Imperial College London
% All rights reserved.

if nargin<2 %~exist('showTaskGraph','var')
    showTaskGraph = false;
end

plotGraph(self);
if showTaskGraph
    plotTaskGraph(self);
end
end
