classdef Model < Copyable
    % Abstract parent class for all models
    %
    % Copyright (c) 2012-2022, Imperial College London
    % All rights reserved.
    
    properties (Hidden)
        attribute;
        lineVersion;
    end
    
    properties
        name;
    end
    
    methods
        %Constructor
        function self = Model(name)
            % SELF = MODEL(NAME)
            %[~,lineVersion] = system('git describe'); 
            lineVersion = '2.0.23';
            %persistent lineSplashScreenShown
            %if isempty(lineSplashScreenShown) || lineSplashScreenShown
            %    lineSplashScreenShown = true;
                %line_printf('LINE solver 2.0 initialized.');
            %end
            lineVersion = strtrim(lineVersion);
            self.setVersion(lineVersion);
            self.setName(name);            
        end
        
        function out = getName(self)
            % OUT = GETNAME()
            
            out = self.name;
        end
        
        function self = setName(self, name)
            % SELF = SETNAME(NAME)
            
            self.name = name;
        end
        
        function v = getVersion(self)
            v = self.lineVersion;
        end        
        
        function self = setVersion(self, version)
            % SELF = SETVERSION(VERSION)
            
            self.lineVersion = version;
        end
    end
    
end
