classdef intermediateCatchEvent < BPMN.catchEvent
% INTERMEDIATECATCHEVENT object as part of a Business Process Modeling Notation (BPMN) model. 
%
% Properties:
% parallelMultiple:     1 if all the conditions in EventDefinition must be active to trigger the event, 0 otherwise
% eventDefinition:      event definition only valid for this event (cell of event definition)
% eventDefinitionRefp:  references to event definitions that are globally available (cell of string)
%
% Copyright (c) 2012-2016, Imperial College London 
% All rights reserved.

properties
end

methods
%public methods, including constructor

    %constructor
    function obj = intermediateCatchEvent(id, name)
        if(nargin == 0)
            disp('Not enough input arguments'); 
            id = int2str(rand()); 
        elseif(nargin <= 1)
            disp('Not enough input arguments'); 
            name = ['intermediateCatchEvent_',id];
        end
        obj@BPMN.catchEvent(id,name); 
    end
    
    %toString
    function myString = toString(obj)
       myString = toString@BPMN.catchEvent(obj);
    end

end
    
end