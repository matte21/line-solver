classdef DisabledClass < JobClass
    % A class of jobs that perpetually cycle inside the model.
    %
    % Copyright (c) 2012-2023, Imperial College London
    % All rights reserved.
    
    properties        
    end
    
    methods
        
        %Constructor
        function self = DisabledClass(model, name, refstat)
            % SELF = DISABLEDCLASS(MODEL, NAME, REFSTAT)
            
            self@JobClass('disabled', name);
            self.type = JobClassType.DISABLED;
            self.priority = 0;
            model.addJobClass(self);
            setReferenceStation(self, refstat);
            
            % set default scheduling for this class at all nodes
            for i=1:length(model.nodes)
                model.nodes{i}.setRouting(self, RoutingStrategy.DISABLED);
                if isa(model.nodes{i},'Join')
                    model.nodes{i}.setStrategy(self, JoinStrategy.STD);
                    model.nodes{i}.setRequired(self, -1);
                end
                %end
            end
        end
        
        function setReferenceStation(class, source)
            % SETREFERENCESTATION(CLASS, SOURCE)
            setReferenceStation@JobClass(class, source);
        end
    end
    
end

