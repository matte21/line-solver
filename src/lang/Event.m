classdef Event
    % A generic event occurring in a Network.
    %
    % Object of the Event class are not passed by handle.
    %
    % Copyright (c) 2012-2023, Imperial College London
    % All rights reserved.
    
    properties
        node;
        event;
        class;
        prob;
        state; % state information when the event occurs (optional)
        t; % timestamp when the event occurs (optional)
        job; % job id (optional) 
    end
    
    methods
        function self = Event(event, node, class, prob, state, t, job)
            % SELF = EVENT(EVENT, NODE, CLASS, PROB, STATE, TIMESTAMP ,job)
                                    
            self.node = node;            
            if ischar(event)
                self.event = EventType.toId(event);
            else
                self.event = event;
            end            
            self.class = class;
            if nargin <4
                prob = NaN;
            end
            self.prob = prob;
            if nargin <5
                state = []; % local state of the node or environment transition
            end
            self.state = state;
            if nargin <6
                t = NaN; % timestamp
            end
            self.t = t;
            if nargin <7
                job = NaN; % timestamp
            end
            self.job = job;
        end

        function vec=getRepres(self)
            vec = [self.node,self.event,self.class];
        end
        
        function print(self)
            % PRINT()
            
            if isnan(self.t)
                line_printf('(%s: node: %d, class: %d)',EventType.toText(self.event),self.node,self.class);
            else
                if isnan(self.job)
                    line_printf('(%s: node: %d, class: %d, time: %d)',EventType.toText(self.event),self.node,self.class,self.t);
                else
                    line_printf('(%s: node: %d, class: %d, job: %d, time: %d)',EventType.toText(self.event),self.node,self.class,self.job,self.t);
                end
            end
        end
    end
    
    
end
