classdef (Sealed) ParameterType
    % An input parameter of a Solver
    %
    % Copyright (c) 2012-2022, Imperial College London
    % All rights reserved.
    
    properties (Constant)
        SvcDemand = 'Service Demand'; % Service Time * Visits
        SvcTime = 'Service Time'; % Service Time * Visits
        Visits = 'Visits'; % Service Time * Visits
        NumJobs = 'Number of Jobs'; % Closed Population
        ArvRate = 'Arrival Rate'; % Class Arrival Rate
        ThinkTime = 'Think Time'; % Class Arrival Rate
        
        ID_SvcDemand = 0;
        ID_SvcTime = 1;
        ID_Visits = 2;
        ID_NumJobs = 3;
        ID_ArvRate = 4;
        ID_ThinkTime = 5;

    end
        
end

