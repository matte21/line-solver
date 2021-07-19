classdef lane < BPMN.baseElement
% LANE object as part of a Business Process Modeling Notation (BPMN) model. 
%
% Properties:
% name:                     name (string)
% flowNodeRef:              IDs of the flow nodes assigned to this lane 
% childLaneSet:             ID of the parent laneSet
% partitionElementRef:      element that specifies a partition value and type 
% partitionElement:         ID of an element that specifies a partition value and type
%
% Copyright (c) 2012-2016, Imperial College London 
% All rights reserved.

properties
    name;                   % string
    flowNodeRef;            % IDs of the flow nodes assigned to this lane 
	childLaneSet;           % ID of the parent laneSet
    partitionElementRef;    % element that specifies a partition value and type 
    partitionElement;       % ID of an element that specifies a partition value and type
end

methods
%public methods, including constructor

    %constructor
    function obj = lane(id, name)
        if(nargin == 0)
            disp('No ID provided for this laneSet'); 
            id = int2str(rand()); 
        elseif(nargin <= 1)
            disp(['No name provided for laneSet ', id]); 
            name = ['lane_',id];
        end
        obj@BPMN.baseElement(id); 
        obj.name = name;
    end
    
    function obj = addFlowNodeRef(obj, flowNodeRef)
       if nargin > 1
            if isempty(obj.flowNodeRef)
                obj.flowNodeRef = cell(1);
                obj.flowNodeRef{1} = flowNodeRef;
            else
                obj.flowNodeRef{end+1,1} = flowNodeRef;
            end
       end
    end
    
    function obj = setChildLaneSet(obj, laneSet)
       obj.childLaneSet = laneSet;
    end
    
    %toString
    function myString = toString(obj)
        myString = toString@BPMN.baseElement(obj);
        myString = sprintf([myString, 'name: ', obj.name,'\n']);
    end

end
    
end