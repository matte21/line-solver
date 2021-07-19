classdef endEvent < BPMN.throwEvent
% ENDEVENT object as part of a Business Process Modeling Notation (BPMN) model. 
%
% Properties:
%
% Copyright (c) 2012-2016, Imperial College London 
% All rights reserved.

properties
end

methods
%public methods, including constructor

    %constructor
    function obj = endEvent(id, name)
        if(nargin == 0)
            disp('Not enough input arguments'); 
            id = int2str(rand()); 
        elseif(nargin <= 1)
            disp('Not enough input arguments'); 
            name = ['endEvent_',id];
        end
        obj@BPMN.throwEvent(id,name); 
    end
    
    %toString
    function myString = toString(obj)
        myString = sprintf([myString, 'id: ', obj.id,'\n']);
        myString = sprintf([myString, 'name: ', obj.name,'\n']);
    end

end
    
end