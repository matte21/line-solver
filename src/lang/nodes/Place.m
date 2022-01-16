classdef Place < Station
    % 
    %
    % Copyright (c) 2012-2022, Imperial College London
    % All rights reserved.
    
    properties
        dropid;
        schedStrategies;
        schedStrategy;
        schedStrategyPar;
    end

    methods
        function self = Place(model,name)
            % PLACE(MODEL, NAME)
            
            self@Station(name);
            classes = model.classes;
            self.input = Storage(classes);
            self.output = Linkage(classes);
            self.setModel(model);
            self.model.addNode(self);
            self.server = ServiceTunnel();

            %numOfClasses = [];
            self.numberOfServers = 1;
            self.schedStrategy = SchedStrategy.FCFS;
            self.schedStrategyPar = [];

            self.classCap = [];
            self.cap = [];
            self.schedStrategies = [];
        end

        function init(self)
            numOfClasses = length(self.model.classes);
            self.schedStrategy = SchedStrategy.FCFS;
            self.schedStrategyPar = zeros(1,numOfClasses);

            self.classCap = Inf(1,numOfClasses);
            self.cap = Inf;
            self.dropid = [];
            for r=1:numOfClasses
                self.dropid(r) = DropStrategy.ID_WAITQ;
            end
            self.schedStrategies = ones(1, numOfClasses);
        end

        function self = setClassCapacity(self, class, capacity)
            % SELF = SETCLASSCAPACITY(CLASS, CAPACITY)
            
            self.classCap(class) = capacity;
        end

        function self = setDropRule(self, class, drop)
            % SELF = SETDROPRULE(CLASS, DROPRULE)

            self.dropid(class) = DropStrategy.toId(drop);
            self.input.inputJobClasses{class}{3}=drop;
        end

        function self = setSchedStrategies(self, class, strategy)
            % SELF = SETSCHEDSTRATEGIES(CLASS, STRATEGY)
            
            self.schedStrategies(class) = strategy;
        end

        function sections = getSections(self)
            % SECTIONS = GETSECTIONS()
            
            sections = {self.input, self.server, self.output};
        end
    end
end

