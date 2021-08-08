classdef messageEventDefinition < BPMN.eventDefinition
% EVENTEVENTDEFINITION object as part of a Business Process Modeling Notation (BPMN) model. 
%
% Properties:
% messageRef:       ID of the message referenced by the event
% operationRef:     ID of the operation used by the message (string)
%
% Copyright (c) 2012-2016, Imperial College London 
% All rights reserved.

properties
    messageRef;     % ID of the message referenced by the event (string)
    operationRef;   % operation used by the message (string)
end

methods
%public methods, including constructor

    %constructor
    function obj = messageEventDefinition(id)
        if(nargin == 0)
            disp('No ID provided for this messageEventDefinition'); 
            id = int2str(rand()); 
        end
        obj@BPMN.eventDefinition(id); 
    end
    
    function obj = setMessageRef(obj, msgRef)
        obj.messageRef = msgRef; 
    end

    function obj = setOperationRef(obj, operRef)
        obj.operationRef = operRef; 
    end

    %toString
    function myString = toString(obj)
        myString = toString@BPMN.eventDefinition(obj);
    end

end
    
end