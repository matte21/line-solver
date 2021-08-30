classdef EventType < Copyable
    % Types of events 
    %
    % Copyright (c) 2012-2021, Imperial College London
    % All rights reserved.
    
    % event major classification
    properties (Constant)
        ID_INIT = -1; % model is initialized (t=0)
        ID_LOCAL = 0;
        ID_ARV = 1; % job arrival
        ID_DEP = 2; % job departure
        ID_PHASE = 3; % service advances to next phase, without departure
        ID_READ = 4; % read cache item
        ID_STAGE = 5; % random environment stage change
        
        INIT = 'init'; 
        LOCAL = 'local';
        ARV = 'arv';
        DEP = 'dep';
        PHASE = 'phase';
        READ = 'read';
        STAGE = 'stage';
    end
    
    methods(Static)
        function text = toText(type)
            % TEXT = TOTEXT(TYPE)
            
            switch type
                case EventType.ID_ARV
                    text = 'ARV';
                case EventType.ID_DEP
                    text = 'DEP';
                case EventType.ID_PHASE
                    text = 'PHASE';
                case EventType.ID_READ
                    text = 'READ';
                case EventType.ID_STAGE
                    text = 'STAGE';
            end
        end
    end
    
end
