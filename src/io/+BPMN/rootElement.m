classdef rootElement < BPMN.baseElement
% ROOTELEMENT abstract class, as part of a Business Process Modeling Notation (BPMN) model. 
%
% Properties:
%
% Copyright (c) 2012-2016, Imperial College London 
% All rights reserved.

properties
end

methods
%public methods, including constructor

    %constructor
    function obj = rootElement(id)
        if(nargin == 0)
            disp('Not enough input arguments'); 
            id = int2str(rand()); 
        end
        obj@BPMN.baseElement(id); 
    end
    
    %toString
    function myString = toString(obj)
        myString = toString@BPMN.baseElement(obj);
    end
    
end
    
end