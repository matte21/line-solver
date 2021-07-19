classdef catchEvent < BPMN.event
% CATCHEVENT abstract class, as part of a Business Process Modeling Notation (BPMN) model. 
%
% Properties:
% parallelMultiple:     1 if all the conditions in EventDefinition must be active to trigger the event, 0 otherwise
% eventDefinition:      event definition only valid for this event (cell of event definition)
% eventDefinitionRefp:  references to event definitions that are globally available (cell of string)
%
% Copyright (c) 2012-2016, Imperial College London 
% All rights reserved.

properties
    parallelMultiple;       % 1 if all the conditions in EventDefinition must be active to trigger the event, 0 otherwise
    eventDefinition;        % event definition only valid for this event (cell of event definition)
    eventDefinitionType;    % type of the associated eventDefinition (cell of string) - Message, Timer, etc
    eventDefinitionRef;     % references to event definitions that are globally available (cell of string)
    eventDefinitionRefType; % type of the associated eventDefinition reference (cell of string) - Message, Timer, etc
end

methods
%public methods, including constructor

    %constructor
    function obj = catchEvent(id, name)
        if(nargin == 0)
            disp('Not enough input arguments'); 
            id = int2str(rand()); 
        elseif(nargin <= 1)
            disp('Not enough input arguments'); 
            name = ['catchEvent_',id];
        end
        obj@BPMN.event(id,name); 
        obj.parallelMultiple = 0; % default
    end
    
    function obj = addEventDefinition(obj, eventDef, type)
       if nargin > 1
            if isempty(obj.eventDefinition)
                obj.eventDefinition = eventDef;
                obj.eventDefinitionType = type;
            else
                obj.eventDefinition(end+1,1) = eventDef;
                obj.eventDefinitionType(end+1,1) = type;
            end
       end
    end
    
    function obj = addEventDefinitionRef(obj, eventDefRef, type)
       if nargin > 1
            if isempty(obj.eventDefinitionRef)
                obj.eventDefinitionRef = cell(1);
                obj.eventDefinitionRef{1} = eventDefRef;
                obj.eventDefinitionRefType = cell(1);
                obj.eventDefinitionRefType{1} = type;
            else
                obj.eventDefinitionRef{end+1,1} = eventDefRef;
                obj.eventDefinitionRefType{end+1,1} = type;
            end
       end
    end
    
    function obj = setParallelMultiple(obj, par)
        obj.parallelMultiple = par;
    end
    
    %toString
    function myString = toString(obj)
        myString = toString@BPMN.event(obj);
    end

end
    
end