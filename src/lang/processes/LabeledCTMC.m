classdef LabeledCTMC < CTMC
    % A class for continuous time Markov chain where transitions are labeled
    %
    % Copyright (c) 2012-2022, Imperial College London
    % All rights reserved.
    
    properties
        eventFilt;
    end
    
    methods
        function self = LabeledCTMC(InfGen, eventFilt, isFinite)
            % SELF = LabeledCTMC(InfGen, eventFilt, isFinite)            
            if nargin<3
                isFinite = true;
            end
            self@CTMC(InfGen, isFinite);
            self.eventFilt = eventFilt;
        end
        
        function pie = embeddedSolve(self, evset)
            % PIE = EMBEDDEDSOLVE(EVENTSET)
            
            if nargin<2
                evset = 1:length(self.eventFilt);
            end
            for e=evset % for every event
                eMAP = MAP(self.infGen - self.eventFilt{e}, self.eventFilt{e});
                pie{e} = eMAP.getEmbeddedProb;
                if issym(pie{e})
                    pie{e}=simplify(pie{e})';
                end
            end
        end
    end
end
