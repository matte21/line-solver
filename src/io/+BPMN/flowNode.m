classdef flowNode < BPMN.flowElement
% FLOWNODE abstract class, as part of a Business Process Modeling Notation (BPMN) model. 
%
% Properties:
% incoming:     list of incoming flows (cell of string)
% outgoing:     list of outgoing flows (cell of string)
%
% Copyright (c) 2012-2016, Imperial College London 
% All rights reserved.

properties
    incoming;       % list of incoming flows (cell of string)
    outgoing;       % list of outgoing flows (cell of string)
end

methods
%public methods, including constructor

    %constructor
    function obj = flowNode(id, name)
        if(nargin == 0)
            disp('Not enough input arguments'); 
            id = int2str(rand()); 
        elseif(nargin <= 1)
            disp('Not enough input arguments'); 
            name = ['flowNode_',id];
        end
        obj@BPMN.flowElement(id,name); 
    end
    
    function obj = addIncoming(obj, flow)
       if nargin > 1
            if isempty(obj.incoming)
                obj.incoming = cell(1);
                obj.incoming{1} = flow;
            else
                obj.incoming{end+1,1} = flow;
            end
       end
    end
    
    function obj = addOutgoing(obj, flow)
       if nargin > 1
            if isempty(obj.outgoing)
                obj.outgoing = cell(1);
                obj.outgoing{1} = flow;
            else
                obj.outgoing{end+1,1} = flow;
            end
       end
    end
    
    %toString
    function myString = toString(obj)
        myString = toString@BPMN.flowElement(obj);
    end

end
    
end