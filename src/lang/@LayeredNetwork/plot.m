function plot(self,useNodes, showProcs)
% PLOT(SELF,USENODES, SHOWPROCS)

% Copyright (c) 2012-2021, Imperial College London
% All rights reserved.

if nargin<2 %~exist('useNodes','var')
    useNodes = true;
end
if nargin<3 %~exist('showProcs','var')
    showProcs = true;
end

[lqnGraph,taskGraph] = getGraph(self);

%figure;
%plot(taskGraph,'Layout','layered','NodeLabel',taskGraph.Nodes.Node);
%title('Task graph');
figure;
if useNodes
    h = plot(lqnGraph,'Layout','layered','EdgeLabel',lqnGraph.Edges.Weight,'NodeLabel',lqnGraph.Nodes.Node);
else
    h = plot(lqnGraph,'Layout','layered','EdgeLabel',lqnGraph.Edges.Weight,'NodeLabel',lqnGraph.Nodes.Name);
end
row = dataTipTextRow('multiplicity',lqnGraph.Nodes.Mult);
h.DataTipTemplate.DataTipRows(2) = row;
row = dataTipTextRow('hostDemand',lqnGraph.Nodes.D);
h.DataTipTemplate.DataTipRows(3) = row;
row = dataTipTextRow('scheduling',cellfun(@(c) c.scheduling,lqnGraph.Nodes.Object,'UniformOutput',false));
h.DataTipTemplate.DataTipRows(end+1) = row;
title(['Model: ',self.name]);

if showProcs
    for r=findstring(lqnGraph.Nodes.Type,'PS')
        if r>0
            highlight(h,r,'NodeColor','white')
        end
    end
    for r=findstring(lqnGraph.Nodes.Type,'AH')
        if r>0
            highlight(h,r,'NodeColor','cyan')
        end
    end
end

for r=findstring(lqnGraph.Nodes.Type,'T')
    if r>0
        highlight(h,r,'NodeColor','magenta')
    end
end

for r=findstring(lqnGraph.Nodes.Type,'R')
    if r>0
        highlight(h,r,'NodeColor','red')
    end
end

for r=findstring(lqnGraph.Nodes.Type,'H')
    if r>0
        highlight(h,r,'NodeColor','black')
    end
end

for r=findstring(lqnGraph.Nodes.Type,'E')
    if r>0
        highlight(h,r,'NodeColor','green')
    end
end

end
