classdef Trace < Replayer
    % Empirical time series from a trace, alias for Replayer
    %
    % Copyright (c) 2012-2021, Imperial College London
    % All rights reserved.
        
    methods
        %Constructor
        function self = Trace(data)
            % SELF = TRACE(data)
            self@Replayer(data);
        end
    end
end

