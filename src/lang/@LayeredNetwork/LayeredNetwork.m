classdef LayeredNetwork < Model & Ensemble
    % A layered queueing network model.
    %
    % Copyright (c) 2012-2022, Imperial College London
    % All rights reserved.

    properties (GetAccess = 'private', SetAccess='private')
        aux;
    end

    properties (Hidden)
        indexes = struct();    % struct of objects
        lqnGraph; % digraph representation of all dependencies
        taskGraph; % digraph representation of task dependencies
        layerGraph;
        topoOrder;
        dfsMarks;
        clientTask;
        nodeNames;
        nodeDep; % (i,1) = procId, (i,2) = taskId, (i,3) = entryId, NaN is n/a
        endNodes;
        nodeMult;
        edgeWeight;
        param; % Avg performance metrics are input parameters in LQNs

        syncCall = cell(1,0);
        asyncCall = cell(1,0);
        syncSource = cell(1,0);
        asyncSource = cell(1,0);
        syncDest = cell(1,0);
        asyncDest = cell(1,0);
        chains = cell(1,0);
        serverName = cell(1,0);
        isCall = cell(1,0);
    end

    properties
        hosts = [];
        tasks = [];
        reftasks = [];
        activities = [];
        entries = [];
        usedFeatures; % cell with structures of booleans listing the used classes
        % it must be accessed via getUsedLangFeatures
    end

    methods
        %public methods, including constructor

        function self = reset(self, isHard)
            if nargin<2
                isHard = false;
            end
            self.lqnGraph = [];
            self.taskGraph = [];
            self.ensemble = {};
            self.aux = struct();
            self.indexes.hosts = [];
            self.indexes.tasks = [];
            self.indexes.reftasks = [];
            self.indexes.entries = [];
            self.indexes.activities = [];
            if isHard
                self.hosts = {};
                self.tasks = {};
                self.reftasks = {};
                self.entries = {};
                self.activities = {};
            end
            self.init;
        end

        % constructor
        function self = LayeredNetwork(name, filename)
            % SELF = LAYEREDNETWORK(NAME, FILENAME)

            self@Ensemble({})
            if nargin<1 %~exist('name','var')
                [~,name]=fileparts(lineTempName);
            end
            self@Model(name);
            self.aux = struct();
            self.lqnGraph = [];
            self.taskGraph = [];
            self.ensemble = {};
            self.hosts = {};
            self.tasks = {};
            self.reftasks = {};
            self.entries = {};
            self.activities = {};
            self.indexes.hosts = [];
            self.indexes.tasks = [];
            self.indexes.reftasks = [];
            self.indexes.entries = [];
            self.indexes.activities = [];
            self.param.Nodes.RespT = [];
            self.param.Nodes.Tput = [];
            self.param.Nodes.Util = [];
            self.param.Edges.RespT = [];
            self.param.Edges.Tput = [];

            if nargin>=2 %exist('filename','var')
                self = LayeredNetwork.parseXML(filename, false);
                self.init;
            end
            try
                jline.lang.distributions.Immediate();
            catch
                javaaddpath(which('linesolver.jar'));
                import jline.*;
            end
        end

        function self = init(self)
            % SELF = INIT()
            self.generateGraph;
            self.initDefault;
            self.param.Nodes.RespT = [];
            self.param.Nodes.Tput = [];
            self.param.Nodes.Util = [];
            self.param.Nodes.QLen = [];
            self.param.Edges.RespT = [];
            self.param.Edges.Tput = [];
            self.param.Edges.QLen = [];
        end

        self = generateGraph(self);
        [lqnGraph,taskGraph] = getGraph(self)
        self = setGraph(self,lqnGraph,taskGraph)
        layerGraph = getGraphLayers(self)

        function G = summary(self)
            % G = SUMMARY()

            G = self.getGraph;
        end

        bool = isValid(self)
        self = update(self)
        self = updateParam(self, AvgTable, netSortAscending)
        self = initDefault(self)
        plot(self, useNodes, showProcs, showTaskGraph)
    end

    methods
        % these methods access the graph functions
        [entry, entryFullName] = findEntryOfActivity(self,activity)
        idx = findEdgeIndex(self,source,dest)
        entries = listEntriesOfTask(self,task);
        acts = listActivitiesOfEntry(self,entry);

        % these methods extract node data from lqnGraph.Nodes
        idx = getNodeIndex(self,node) %converted
        idx = getNodeIndexInTaskGraph(self,node)
        fullName = getNodeFullName(self,node)
        name = getNodeName(self,node,useNode)
        obj = getNodeObject(self,node)
        proc = getNodeHost(self,node)
        task = getNodeTask(self,nodeNameOrIdx)
        type = getNodeType(self,nodeNameOrIdx)

        writeSRVN(self,filename);
        writeXML(self,filename,true);
    end

    methods

        LQN = getStruct(self);

        function E = getNumberOfLayers(self)
            % E = GETNUMBEROFLAYERS()

            E = getNumberOfModels(self);
        end

        function E = getNumberOfModels(self)
            % E = GETNUMBEROFMODELS()

            if isempty(self.ensemble)
                self.ensemble = getEnsemble(self);
            end
            E = length(self.ensemble);
        end

        function layers = getLayers(self)
            % LAYERS = GETLAYERS()

            layers = getEnsemble(self);
        end

        % setUsedFeatures : records that a certain language feature has been used
        function self = setUsedFeatures(self,e,className)
            % SELF = SETUSEDFEATURES(SELF,E,CLASSNAME)

            self.usedFeatures{e}.setTrue(className);
        end

        function self = initUsedFeatures(self)
            % SELF = INITUSEDFEATURES()

            for e=1:getNumberOfModels(self)
                self.usedFeatures{e} = SolverFeatureSet;
            end
        end

        function usedFeatures = getUsedLangFeatures(self)
            % USEDFEATURES = GETUSEDLANGFEATURES()

            E = getNumberOfLayers(self);
            usedFeatures = cell(1,E);
            for e=1:E
                usedFeatures{e} = self.ensemble{e}.getUsedLangFeatures;
            end
            self.usedFeatures = usedFeatures;
        end

        function [lambda,D,N,Z,mu,S]= getProductFormParameters(self)
            % [LAMBDA,D,N,Z,MU,S]= GETPRODUCTFORMPARAMETERS()

            ensemble = self.getEnsemble;
            for e=1:length(ensemble)
                [lambda{e,1},D{e,1},N{e,1},Z{e,1},mu{e,1},S{e,1}] = ensemble{e}.getProductFormParameters;
            end
        end

        function [lambda,D,N,Z,mu,S]= getProductFormChainParameters(self)
            % [LAMBDA,D,N,Z,MU,S]= GETPRODUCTFORMCHAINPARAMETERS()

            ensemble = self.getEnsemble;
            for e=1:length(ensemble)
                [lambda{e,1},D{e,1},N{e,1},Z{e,1},mu{e,1},S{e,1}] = ensemble{e}.getProductFormChainParameters;
            end
        end

    end

    methods (Static)
        function myLN = readXML(filename, verbose)
		        myLN = LayeredNetwork.parseXML(filename, verbose);
		end
        myLN = parseXML(filename, verbose)
    end
end
