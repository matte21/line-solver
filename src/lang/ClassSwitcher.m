classdef ClassSwitcher < ServiceSection
% Copyright (c) 2012-2019, Imperial College London
% All rights reserved.
    
    properties
        csFun;
        classes;
    end
    
    methods
        %Constructor
        function self = ClassSwitcher(classes, name)
            self = self@ServiceSection(name);            
            self.classes = classes;
            self.numberOfServers = 1;
            self.serviceProcess = {};
        end
    end
        
end