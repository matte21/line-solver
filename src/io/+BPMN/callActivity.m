classdef callActivity < activity
% CALLACTIVITY object, as part of a Business Process Modeling Notation (BPMN) model. 
%
% Properties:
% id:                   unique identifier (string)
% name:                 server name (string)
% calledElement:        ID of the element called by this activity, a process or a global task (string)
%
% Copyright (c) 2012-2016, Imperial College London 
% All rights reserved.

properties
    calledElement;      % ID of the element called by this activity, a process or a global task (string)
end

methods
%public methods, including constructor

    %constructor
    function obj = callActivity(id, name)
        if(nargin == 0)
            disp('Not enough input arguments'); 
            id = int2str(rand()); 
        elseif(nargin <= 1)
            disp('Not enough input arguments'); 
            name = ['task_',id];
        end
        obj@activity(id,name); 
    end
    
    function obj = setCalledElement(obj, elem)
        obj.callElement = elem; 
    end
    
    %toString
    function myString = toString(obj)
        myString = sprintf(['<<<<<<<<<<\nname: ', obj.name,'\n']);
        myString = sprintf([myString, 'id: ', obj.id,'\n']);
    end

end
    
end