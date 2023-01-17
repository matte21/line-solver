classdef GlobalConstants
    % Distrib for global constants
    %
    % Copyright (c) 2012-2023, Imperial College London
    % All rights reserved.

    methods (Static)
        function do=LINEDoChecks()
            global LINEDoChecks
            do = LINEDoChecks;
        end
        function stdo=StdOut()
            global LINEStdOut
            stdo = LINEStdOut;
        end
        function tol=Inf()
            global LINEInf
            tol = LINEInf;
        end
        function tol=CoarseTol()
            global LINECoarseTol
            tol = LINECoarseTol;
        end
        function tol=FineTol()
            global LINEFineTol
            tol = LINEFineTol;
        end
        function verbose=Verbose()
            global LINEVerbose
            verbose = LINEVerbose;
        end
        function ver=Version()
            global LINEVersion
            ver = LINEVersion;
        end
    end
end
