classdef resource < BPMN.baseElement
% RESOURCE describes resources in a Business Process Modeling Notation (BPMN) model, 
% according to the BPMN entension
%
% Properties:
% name:                 name (string)
% multiplicity:         number of parallel resources (int)
% scheduling:           scheduling policy (string)
% assigments:           list of tasks ID (col 1) and mean execution time (col 2) (cell of strings - 2 cols)
%
% Copyright (c) 2012-2016, Imperial College London 
% All rights reserved.

properties
    name;           % string
    multiplicity;   % int
    scheduling;     % string
    assignments;     % cell of strings - 2 cols
end

methods
%public methods, including constructor

    %constructor
    function obj = resource(id, name, multiplicity, scheduling)
        if(nargin == 0)
            disp('No ID provided for this resource'); 
            id = int2str(rand()); 
        end
        if(nargin <= 1)
            disp(['No name provided for resource with id ', id]); 
            name = ['resource_',id];
        end
        if(nargin <= 2)
            disp(['No multiplicity provided for resource with id ', id]); 
            multiplicity = 1;
        end
        if(nargin <= 3)
            disp(['No scheduling provided for resource with id ', id]); 
            scheduling = 'ps';
        end
        obj@BPMN.baseElement(id); 
        obj.name = name;
        obj.multiplicity = multiplicity;
        obj.scheduling = scheduling;
    end
    
    function obj = addAssignment(obj, taskID, meanExecTime)
       if nargin > 1
            if isempty(obj.assignments)
                obj.assignments = cell(1,2);
                obj.assignments{1,1} = taskID;
                obj.assignments{1,2} = meanExecTime;
            else
                obj.assignments{end+1,1} = taskID;
                obj.assignments{end,2} = meanExecTime; 
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