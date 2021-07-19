classdef timerEventDefinition < BPMN.eventDefinition
% TIMEEVENTDEFINITION object as part of a Business Process Modeling Notation (BPMN) model. 
%
% Properties:
% timeDuration      duration of the event (string - expression)
% timeDate:         duration of the event (string - expression)
% timeCycle:        duration of the event (string - expression)
%
% Copyright (c) 2012-2016, Imperial College London 
% All rights reserved.

properties
    timeDuration;   % duration of the event (string - expression)
	timeDate;       % duration of the event (string - expression)
    timeCycle;      % duration of the event (string - expression)
end

methods
%public methods, including constructor

    %constructor
    function obj = timerEventDefinition(id)
        if(nargin == 0)
            disp('No ID provided for this timerEventDefinition'); 
            id = int2str(rand()); 
        end
        obj@BPMN.eventDefinition(id); 
    end
    
    function obj = setTimeDuration(obj, time)
        obj.timeDuration = time; 
        obj.timeDate  = []; 
        obj.timeCycle = []; 
    end
    
    function obj = setTimeDate(obj, time)
        obj.timeDuration = []; 
        obj.timeDate  = time; 
        obj.timeCycle = []; 
    end
    
    function obj = setTimeCycle(obj, time)
        obj.timeDuration = []; 
        obj.timeDate  = []; 
        obj.timeCycle = time; 
    end
    
    
    %toString
    function myString = toString(obj)
        myString = toString@BPMN.eventDefinition(obj);
    end

end
    
end
