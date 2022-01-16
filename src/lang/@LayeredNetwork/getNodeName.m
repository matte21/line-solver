function name = getNodeName(self,node,useNode)
% NAME = GETNODENAME(SELF,NODE,USENODE)

% Copyright (c) 2012-2022, Imperial College London
% All rights reserved.
G = self.lqnGraph;
if nargin<3 || useNode == false  %~exist('useNode','var')
    name = G.Nodes.Name{node};
else
    name = G.Nodes.Node{node};
end
end
