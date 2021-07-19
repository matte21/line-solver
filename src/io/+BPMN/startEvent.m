classdef startEvent < BPMN.catchEvent
% STARTEVENT object, as part of a Business Process Modeling Notation (BPMN) model. 
%
% Properties:
% id:                   unique identifier (string)
% name:                 server name (string)
%
% Copyright (c) 2012-2016, Imperial College London 
% All rights reserved.

properties
    isInterrupting;
end

methods
%public methods, including constructor

    %constructor
    function obj = startEvent(id, name)
        if(nargin == 0)
            disp('Not enough input arguments'); 
            id = int2str(rand()); 
        elseif(nargin <= 1)
            disp('Not enough input arguments'); 
            name = ['intermediateCatchEvent_',id];
        end
        obj@BPMN.catchEvent(id,name); 
        obj.isInterrupting = 1; % default
    end
    
    function obj = setIsInterrumping(obj, isInter)
        obj.isInterrupting = isInter;
    end
    
    %toString
    function myString = toString(obj)
        myString = toString@BPMN.catchEvent(obj);
    end

end
    
end