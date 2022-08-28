function plot(self, useNodes, showHostProcs, showTaskGraph)
% PLOT(SELF, USENODES, SHOWPROCS, SHOWTASKGRAPH)

% Copyright (c) 2012-2022, Imperial College London
% All rights reserved.

if nargin<2 %~exist('useNodes','var')
    useNodes = true;
end
if nargin<3 %~exist('showProcs','var')
    showHostProcs = true;
end
if nargin<4 %~exist('showTaskGraph','var')
    showTaskGraph = false;
end

[lqnGraph,taskGraph] = getGraph(self);

if showTaskGraph
    figure;
    plot(taskGraph,'Layout','layered','NodeLabel',taskGraph.Nodes.Node);
    title('Task graph');
end
figure;
if useNodes
    h = plot(lqnGraph,'Layout','layered','EdgeLabel',lqnGraph.Edges.Weight,'NodeLabel',strrep(lqnGraph.Nodes.Node, '_', '\_'),'MarkerSize',6);
else
    h = plot(lqnGraph,'Layout','layered','EdgeLabel',lqnGraph.Edges.Weight,'NodeLabel',strrep(lqnGraph.Nodes.Name, '_', ''),'MarkerSize',6);
end
row = dataTipTextRow('multiplicity',lqnGraph.Nodes.Mult);
h.DataTipTemplate.DataTipRows(2) = row;
row = dataTipTextRow('hostDemand',lqnGraph.Nodes.D);
h.DataTipTemplate.DataTipRows(3) = row;
row = dataTipTextRow('scheduling',cellfun(@(c) c.scheduling,lqnGraph.Nodes.Object,'UniformOutput',false));
h.DataTipTemplate.DataTipRows(end+1) = row;
title(['Model: ',self.name]);

for r=find(lqnGraph.Edges.Pre==1)' %AndFork
    highlight(h,lqnGraph.Edges.EndNodes(r,:),'EdgeColor','m')
end
for r=find(lqnGraph.Edges.Post==1)' % AndJoin
    highlight(h,lqnGraph.Edges.EndNodes(r,:),'EdgeColor','m')
end

if showHostProcs
    for r=findstring(lqnGraph.Nodes.Type,'P')
        if r>0
            highlight(h,r,'NodeColor','white','Marker','h');
        end
    end
    for r=findstring(lqnGraph.Nodes.Type,'A')
        if r>0
            %highlight(h,r,'NodeColor','blue','Marker','o');
        end
    end
end

for r=findstring(lqnGraph.Nodes.Type,'T')
    if r>0
        highlight(h,r,'NodeColor','magenta','Marker','v');
    end
end

for r=findstring(lqnGraph.Nodes.Type,'R')
    if r>0
        highlight(h,r,'NodeColor','#EDB120','Marker','^');
    end
end

for r=findstring(lqnGraph.Nodes.Type,'H')
    if r>0
        highlight(h,r,'NodeColor','black','Marker','h');
    end
end

for r=findstring(lqnGraph.Nodes.Type,'E')
    if r>0
        highlight(h,r,'NodeColor','red','Marker','s');
    end
end

end
