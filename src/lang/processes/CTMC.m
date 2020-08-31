classdef CTMC < Process
    % An abstract class for a continuous time Markov chain
    %
    % Copyright (c) 2012-2020, Imperial College London
    % All rights reserved.
    
    properties
        infGen;
        stateSpace;
        isfinite;
    end
    
    methods
        function self = CTMC(InfGen, isFinite)
            % SELF = CTMC(InfGen, isInfinite)
            self@Process('CTMC', 1);
            
            self.infGen = InfGen;
            self.stateSpace = [];
            if nargin < 2
                self.isfinite = true;
            else
                self.isfinite = isFinite;
            end
        end
        
        function setStateSpace(self,stateSpace)
            self.stateSpace  = stateSpace;
        end
        
        function plot(self)
            nodeLbl = {};
            if ~isempty(self.stateSpace)
                for s=1:size(self.stateSpace,1)
                    if size(self.stateSpace,2)>1
                        nodeLbl{s} = sprintf('%s%d', sprintf('%d,', self.stateSpace(s,1:end-1)), self.stateSpace(s,end));
                    else
                        nodeLbl{s} = sprintf('%d', self.stateSpace(s,end));
                    end
                end
            end
            Q0 = self.infGen - diag(diag(self.infGen));
            [I,J,q]=find(Q0);
            edgeLbl = {};
            if ~isempty(self.stateSpace)
                for t=1:length(I)
                    edgeLbl{end+1,1} = nodeLbl{I(t)};
                    edgeLbl{end,2} = nodeLbl{J(t)};
                    edgeLbl{end,3} = sprintf('%.2f',(q(t)));
                end
            else
                for t=1:length(I)
                    edgeLbl{end+1,1} = num2str(I(t));
                    edgeLbl{end,2} = num2str(J(t));
                    edgeLbl{end,3} = sprintf('%.2f',(q(t)));
                end
            end
            if length(nodeLbl) <= 6
                colors = {}; for i=1:length(nodeLbl), colors{i}='w'; end
                graphViz4Matlab('-adjMat',Q0,'-nodeColors',colors,'-nodeLabels',nodeLbl,'-edgeLabels',edgeLbl,'-layout',Circularlayout);
            else
                graphViz4Matlab('-adjMat',Q0,'-nodeLabels',nodeLbl,'-edgeLabels',edgeLbl,'-layout',Springlayout);
            end
        end
    end
    
    methods
        
    end
end
