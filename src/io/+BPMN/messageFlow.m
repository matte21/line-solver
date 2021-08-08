classdef messageFlow < BPMN.baseElement
% MESSAGEFLOW object, as part of a Business Process Modeling Notation (BPMN) model. 
%
% Properties:
% name:                 server name (string)
% isExecutable:         boolean
% quantity:             number of servers (integer)
% scheduling:           service scheduling policy  (string in {'IS', 'FCFS', 'PS'} )
%
% Copyright (c) 2012-2016, Imperial College London 
% All rights reserved.

properties
    name;                   % string
    sourceRef;              % the id of the corresponding process object (string)
    targetRef;              % the id of the corresponding process object (string)
    messageRef;             % id of the message element to which this flow belongs to (string)
end

methods
%public methods, including constructor

    %constructor
    function obj = messageFlow(id, name, messageRef,sourceRef,targetRef) 
        if(nargin == 0)
            disp('Not enough input arguments'); 
            id = int2str(rand()); 
        elseif(nargin <= 1)
            disp('Not enough input arguments'); 
            name = ['messageFlow_',id];
        elseif(nargin <= 2)
            disp('Not enough input arguments'); 
            messageRef = '';
        elseif(nargin <= 3)
            disp('Not enough input arguments'); 
            sourceRef = '';
        elseif(nargin <= 4)
            disp('Not enough input arguments'); 
            targetRef = '';
        end
        obj@BPMN.baseElement(id);
        obj.name = name;
        obj.messageRef = messageRef;
        obj.sourceRef = sourceRef;
        obj.targetRef = targetRef;
    end
    
    
    %toString
    function myString = toString(obj)
        myString = toString@BPMN.baseElement(obj);
        myString = sprintf([myString, 'name: ', obj.name,'\n']);
        myString = sprintf([myString, 'messageRef: ',  obj.messageRef,'\n']);
        myString = sprintf([myString, 'sourceRef: ',  obj.sourceRef,'\n']);
        myString = sprintf([myString, 'targetRef: ',  obj.targetRef,'\n']);
    end

end
    
end