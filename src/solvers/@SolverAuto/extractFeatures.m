function features = extractFeatures(model)
% This is a helper function for tabulateData. It takes in a
% Network object (QN model in LINE) and returns a vector
% of 15 features as shown below

	sn = model.getStruct;   
    features = zeros(1, 15);
    
    % Station and scheduling information
    features(1) = sum(sn.schedid == SchedStrategy.ID_FCFS); % Num FCFS queues
    features(2) = sum(sn.schedid == SchedStrategy.ID_PS); % Num PS queues
    features(3) = sum(sn.schedid == SchedStrategy.ID_INF); % Num delays
    features(4) = sn.nnodes - sn.nstations; % Num CS nodes
    features(5) = sum(sn.nservers(~isinf(sn.nservers))); % Num queue servers
    
    % Job information
    features(6) = sn.nchains; % Num chains
    features(7) = sn.nclosedjobs; % Number of jobs in the system
    
    % Service process information
    features(8:10) = getServiceDist(model); % Num of each distribution type
    features(11) = mean(sn.rates, 'all', 'omitnan'); % Avg service rate
    features(12) = mean(sn.scv, 'all', 'omitnan'); % Avg SCV
    features(13) = mean(sn.phases, 'all', 'omitnan'); % Avg phases
    
    % Misc
    features(14) = sum(sn.nodetype == NodeType.Queue) == 1; % If only 1 Queue, special for nc.mmint
    features(15) = model.hasProductFormSolution; % Check if model has product form solution
end

function data = getServiceDist(model)
    numexp = 0;
    numhyperexp = 0;
    numerlang = 0;
    
    for i = 1 : model.getNumberOfStations
        for j = 1 : model.getNumberOfClasses
            switch model.stations{i}.serviceProcess{j}.name
               case 'Exponential'
                   numexp = numexp + 1;
               case 'HyperExp'
                   numhyperexp = numhyperexp + 1;
               case 'Erlang'
                   numerlang = numerlang + 1;
            end
        end
    end

    data = [numexp numhyperexp numerlang];
end