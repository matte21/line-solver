classdef laneSet < BPMN.baseElement
% LANESET object as part of a Business Process Modeling Notation (BPMN) model. 
%
% Properties:
% name:             name (string)
% lane:             set of lanes 
%
% Copyright (c) 2012-2016, Imperial College London 
% All rights reserved.

properties
    name;       % string
    lane;       % set of lanes 
end

methods
%public methods, including constructor

    %constructor
    function obj = laneSet(id, name)
        if(nargin == 0)
            disp('No ID provided for this laneSet'); 
            id = int2str(rand()); 
        elseif(nargin <= 1)
            disp(['No name provided for laneSet ', id]); 
            name = ['laneSet_',id];
        end
        obj@BPMN.baseElement(id); 
        obj.name = name;
    end
    
    function obj = addLane(obj, lane)
       if nargin > 1
            if isempty(obj.lane)
                obj.lane = lane;
            else
                obj.lane(end+1,1) = lane;
            end
       end
    end
    
    %toString
    function myString = toString(obj)
        myString = toString@BPMN.baseElement(obj);
        myString = sprintf([myString, 'name: ', obj.name,'\n']);
    end

end
    
end