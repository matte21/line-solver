classdef flowElement < BPMN.baseElement
% FLOWELEMENT abstract class, as part of a Business Process Modeling Notation (BPMN) model. 
%
% Properties:
% name:                 name (string)
% auditing:             auditing information (cell of string)
% monitoring:           monitoring information (cell of string)
%
% Copyright (c) 2012-2016, Imperial College London 
% All rights reserved.

properties
    name;       % string
    auditing;   % auditing information (cell of string)
    monitoring; % monitoring information (cell of string)
end

methods
%public methods, including constructor

    %constructor
    function obj = flowElement(id, name)
        if(nargin == 0)
            disp('Not enough input arguments'); 
            id = int2str(rand()); 
        elseif(nargin <= 1)
            disp('Not enough input arguments'); 
            name = ['flowElement_',id];
        end
        obj@BPMN.baseElement(id); 
        obj.name = name;
    end
    
    function obj = addAuditing(obj, audit)
       if nargin > 1
            if isempty(obj.auditing)
                obj.auditing = cell(1);
                obj.auditing{1} = audit;
            else
                obj.auditing{end+1,1} = audit;
            end
       end
    end
    
    function obj = addMonitoring(obj, monit)
       if nargin > 1
            if isempty(obj.auditing)
                obj.monitoring = cell(1);
                obj.monitoring{1} = monit;
            else
                obj.monitoring{end+1,1} = monit;
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