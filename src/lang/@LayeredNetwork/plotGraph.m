function plotGraph(self, method)
% PLOTGRAPH(SELF, METHOD)
%
% METHOD: nodes, names or ids

% Copyright (c) 2012-2023, Imperial College London
% All rights reserved.

if nargin<2 %~exist('useNodes','var')
    method = 'nodes';
end

lqn = self.getStruct;
T = lqn.graph;
figure;
switch method
    case 'nodes'
        h = plot(digraph(T),'Layout','layered','NodeLabel',lqn.hashnames);
    case 'names'
        h = plot(digraph(T),'Layout','layered','NodeLabel',lqn.names);
    case 'ids'
        h = plot(digraph(T),'Layout','layered');
end
title(['Model: ',self.name]);

%for r=find(lqnGraph.Edges.Pre==1)' %AndFork
%    highlight(h,lqnGraph.Edges.EndNodes(r,:),'EdgeColor','m')
%end
%for r=find(lqnGraph.Edges.Post==1)' % AndJoin
%    highlight(h,lqnGraph.Edges.EndNodes(r,:),'EdgeColor','m')
%end

for r=find(lqn.type==LayeredNetworkElement.HOST)'
    if r>0
        highlight(h,r,'NodeColor','black','Marker','h');
    end
end

for r=find(lqn.type==LayeredNetworkElement.ACTIVITY)'
    if r>0
        highlight(h,r,'NodeColor','blue','Marker','o');
    end
end

for r=find(lqn.type==LayeredNetworkElement.ACTIVITY)'
    p = find(lqn.graph(:,r))';
    if r>0
        switch lqn.actpretype(r)
            case ActivityPrecedenceType.ID_PRE_AND
               % highlight(h,p,'NodeColor','magenta','Marker','o');
        end
    end
    p = find(lqn.graph(r,:))';
    if r>0
        switch lqn.actposttype(r)
            case ActivityPrecedenceType.ID_POST_AND
               % highlight(h,p,'NodeColor','magenta','Marker','o');
        end
    end
end

for r=find(lqn.type==LayeredNetworkElement.TASK)'
    if r>0
        if lqn.isref(r)
            highlight(h,r,'NodeColor','#EDB120','Marker','^');
        else
            highlight(h,r,'NodeColor','magenta','Marker','v');
        end
    end
end

for r=find(lqn.type==LayeredNetworkElement.ENTRY)'
    if r>0
        highlight(h,r,'NodeColor','red','Marker','s');
    end
end

mult = nan(lqn.nidx,1);
mult(1:(lqn.tshift+lqn.ntasks),1)=lqn.mult;
row = dataTipTextRow('multiplicity',mult);
h.DataTipTemplate.DataTipRows(2) = row;
D = 0*lqn.mult;
for i=1:length(lqn.hostdem)
    if ~isempty(lqn.hostdem{i})
        D(i) = lqn.hostdem{i}.getMean;
    end
end
row = dataTipTextRow('hostDemand',D);
h.DataTipTemplate.DataTipRows(end+1) = row;
sched = cell(lqn.nidx,1);
for i=1:length(sched)
    sched{i} = 'n/a';
end
sched(1:(lqn.tshift+lqn.ntasks),1)=lqn.sched;
row = dataTipTextRow('scheduling',sched);
h.DataTipTemplate.DataTipRows(end+1) = row;
end
