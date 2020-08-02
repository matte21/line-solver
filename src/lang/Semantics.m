classdef Semantics
    % Semantic interpretation of state
    %
    % Copyright (c) 2012-2020, Imperial College London
    % All rights reserved.
    
    properties (Constant)
        ID_FAST = 4;
        ID_SLOW = 3;
        ID_REPAIR = 3;
        ID_DOWN = 1;
        ID_UP = 0;
        ID_UNSPECIFIED = -1;
        
        UNSPECIFIED = 'Unspecified';
        UP = 'UP'; % all nodes up 
        DOWN = 'DOWN'; % one or more nodes down
        REPAIR = 'REPAIR';
        FAST = 'FAST';
        SLOW = 'SLOW';
    end
    
    methods (Access = private)
        %private so that it cannot be instatiated.
        function out = Semantics
            % OUT = ENVSTATETYPE
            
        end
    end
    
    methods (Static)
        function typeId = getId(semanatics)
            % SID = GETID(TYPE)
            % Classifies the environment state types
            switch semanatics
                case Semantics.UP
                    typeId = Semantics.ID_UP;
                case Semantics.DOWN
                    typeId = Semantics.ID_DOWN;
                case Semantics.UNSPECIFIED
                    typeId = Semantics.ID_UNSPECIFIED;
                case Semantics.REPAIR
                    typeId = Semantics.ID_REPAIR;
                case Semantics.FAST
                    typeId = Semantics.ID_FAST;
                case Semantics.SLOW
                    typeId = Semantics.ID_SLOW;
                otherwise
                    warning('Unknown state type - replaced with unspecified.');
                    typeId = Semantics.ID_UNSPECIFIED;
            end
        end
        
        function text = toText(SID)
            % TEXT = TOTEXT(SID)
            switch SID
                case Semantics.ID_UP
                    text = 'Up';
                case Semantics.ID_DOWN
                    text = 'Down';
                case Semantics.ID_UNSPECIFIED
                    text = 'Unspecified';
                case Semantics.ID_REPAIR
                    text = 'Repair';
                case Semantics.ID_FAST
                    text = 'Fast';
                case Semantics.ID_SLOW
                    text = 'Slow';
                otherwise
                    warning('Unknown state type - replaced with unspecified.');
                    text = 'Unspecified';
            end
        end
    end
end
