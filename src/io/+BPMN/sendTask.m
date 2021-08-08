classdef sendTask < BPMN.task
% SENDTASK object, as part of a Business Process Modeling Notation (BPMN) model. 
%
% Properties:
% id:                   unique identifier (string)
% name:                 server name (string)
%
% Copyright (c) 2012-2016, Imperial College London 
% All rights reserved.

properties
    implementation;     % technology used to implement the Task (string)
    messageRef;         % ID of the message sent by the task (string)
end

methods
%public methods, including constructor

    %constructor
    function obj = sendTask(id, name, implementation)
        if(nargin == 0)
            disp('Not enough input arguments'); 
            id = int2str(rand()); 
        elseif(nargin <= 1)
            disp('Not enough input arguments'); 
            name = ['sendTask_',id];
        elseif(nargin <= 2)
            disp(['No implementation specified for sendTask ',id]); 
            implementation = '';
        end
        obj@BPMN.task(id,name); 
        obj.implementation = implementation;
    end
    
    function obj = setMessageRef(obj, msgRef)
        obj.messageRef = msgRef;
    end
    
    %toString
    function myString = toString(obj)
        myString = sprintf(['<<<<<<<<<<\nname: ', obj.name,'\n']);
        myString = sprintf([myString, 'id: ', obj.id,'\n']);
    end

end
    
end