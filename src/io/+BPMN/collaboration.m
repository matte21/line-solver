classdef collaboration < BPMN.rootElement
% COLLABORATION objects as part of a Business Process Modeling Notation (BPMN) model. 
%
% Properties:
% id:                   unique identifier (string)
% name:                 server name (string)
% participants;         participants in the collaboration (array of particpants)
% messageFlows;         message flows in the collaboration
% processes;            list of process objects participating in the collaboration
%
% Copyright (c) 2012-2016, Imperial College London 
% All rights reserved.


properties
    name;                   % string
    participant;           % participants in the collaboration (array of particpants)
    messageFlow;           % message flows in the collaboration
    process;              % list of process objects participating in the collaboration
end

methods
%public methods, including constructor

    %constructor
    function obj = collaboration(id, name)
        if(nargin == 0)
            disp('Not enough input arguments'); 
            id = int2str(rand()); 
        elseif(nargin <= 1)
            disp('Not enough input arguments'); 
            name = ['collaboration_',id];
        end
        obj@BPMN.rootElement(id); 
        obj.name = name;
        obj.participant = [];
    end
    
    function obj = addParticipant(obj, participant)
        if isempty(obj.participant)
            obj.participant = participant;
        else
           obj.participant(end+1) = participant; 
        end
    end
    
    function obj = addProcess(obj, process)
        if isempty(obj.process)
            obj.process = process;
        else
            obj.process(end+1) = process; 
        end
    end
    
    function obj = addMessageFlow(obj, msgFlow)
        if isempty(obj.messageFlow)
            obj.messageFlow = msgFlow;
        else
            obj.messageFlow(end+1) = msgFlow; 
        end
    end
    
     %toString
    function myString = toString(obj)
        myString = toString@BPMN.rootElement(obj);
        myString = sprintf([myString, 'name: ', obj.name,'\n']);
    end

end
    
end