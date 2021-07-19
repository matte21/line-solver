classdef baseElement
% BASELEMENT abstract class, as part of a Business Process Modeling Notation (BPMN) model. 
%
% Properties:
% id:                   unique identifier (string)
% documentation:        documentation (string)
% extensionElements:    extension elements (string)
%
% Copyright (c) 2012-2016, Imperial College London 
% All rights reserved.

properties
    id;                 % string
    documentation;      % documentation (string)
    extensionElements;  % extension elements (string)
end

methods
%public methods, including constructor

    %constructor
    function obj = baseElement(id)
        if(nargin > 0)
            obj.id = id;
        end
    end
    
    function obj = addDocumentation(obj, doc)
       if nargin > 1
            if isempty(obj.documentation)
                obj.documentation = cell(1);
                obj.documentation{1} = doc;
            else
                obj.documentation{end+1,1} = doc;
            end
       end
    end
    
    %toString
    function myString = toString(obj)
        myString = sprintf(['id: ', obj.id,'\n']);
    end

end
    
end