classdef participant < BPMN.baseElement
% PARTICIPANT object, as part of a Business Process Modeling Notation (BPMN) model. 
%
% Properties:
% id:                   unique identifier (string)
% name:                 server name (string)
% isExecutable:         boolean
% quantity:             number of servers (integer)
% scheduling:           service scheduling policy  (string in {'IS', 'FCFS', 'PS'} )
%
% Copyright (c) 2012-2016, Imperial College London 
% All rights reserved.

properties
    name;                   % string
    processRef;             % the id of the corresponding process object (string)
end

methods
%public methods, including constructor

    %constructor
    function obj = participant(id, name, processRef)
        if(nargin == 0)
            disp('Not enough input arguments'); 
            id = int2str(rand()); 
        elseif(nargin <= 1)
            disp('Not enough input arguments'); 
            name = ['participant_',id];
        elseif(nargin <= 2)
            disp('Not enough input arguments'); 
            processRef = ''; 
        end
        obj@BPMN.baseElement(id); 
        obj.name = name;
        obj.processRef = processRef;
    end
    
    %toString
    function myString = toString(obj)
        myString = toString@BPMN.basetElement(obj);
        myString = sprintf([myString, 'name: ', obj.name,'\n']);
        myString = sprintf([myString, 'processRef: ',  obj.processRef,'\n']);
    end

end
    
end