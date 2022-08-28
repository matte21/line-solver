classdef Node < NetworkElement
    % An abstract for a node in a Network model
    %
    % Copyright (c) 2012-2022, Imperial College London
    % All rights reserved.

    properties
        model;
        input;
        server;
        output;
        index;
    end

    methods(Hidden)
        %Constructor
        function self = Node(name)
            % SELF = NODE(NAME)

            self@NetworkElement(char(name));
            self.index = NaN;
        end

        function self = setModel(self, model)
            % SELF = SETMODEL(MODEL)
            %
            % Add a pointer to the model object

            self.model = model;
        end

        function self = link(self, nodeTo)
            % SELF = LINK(NODETO)
            %
            %

            self.model.addLink(self,nodeTo);
        end

        function self = reset(self)
            % SELF = RESET()
            %
            % Reset internal data structures when the network model is
            % reset

        end
    end

    methods

        function sections = getSections(self)
            % SECTIONS = GETSECTIONS()

            sections = {self.input, self.server, self.output};
        end

        function setProbRouting(self, class, destination, probability)
            % SETPROBROUTING(CLASS, DESTINATION, PROBABILITY)

            setRouting(self, class, RoutingStrategy.PROB, destination, probability);
        end

        function self = setScheduling(self, class, strategy)
            % SETSCHEDULING(CLASS, STRATEGY)

            self.input.inputJobClasses{class.index}{2} = strategy;
        end

        function setRouting(self, class, strategy, par1, par2)
            % SETROUTING(CLASS, STRATEGY, PARAM)
            % SETROUTING(CLASS, STRATEGY, DESTINATION, PROBABILITY)

            if isa(self,'Cache')
                switch strategy
                    case {RoutingStrategy.KCHOICES, RoutingStrategy.WRROBIN, RoutingStrategy.RROBIN}
                        line_error(mfilename,'State-dependent routing not supported with caches. Add instead a Router node after the cache.');
                end
            end
            switch strategy
                case RoutingStrategy.KCHOICES
                    if nargin < 4
                        par1 = 2; % param_k
                    end
                    if nargin < 5
                        par2 = false; % param_memory
                    end
                    param_k = par1;
                    param_memory = par2;
                    self.output.outputStrategy{1, class.index}{2} = RoutingStrategy.toType(strategy);
                    self.output.outputStrategy{1, class.index}{3}{1} = param_k;
                    self.output.outputStrategy{1, class.index}{3}{2} = param_memory;
                case RoutingStrategy.WRROBIN
                    destination = par1;
                    weight = par2;
                    if abs(weight-round(weight)) < Distrib.Tol
                        self.output.outputStrategy{1, class.index}{2} = RoutingStrategy.toType(strategy);
                        if length(self.output.outputStrategy{1, class.index})<3
                            self.output.outputStrategy{1, class.index}{3}{1} = {destination, weight};
                        else
                            self.output.outputStrategy{1, class.index}{3}{end+1} = {destination, weight};
                        end
                    else
                        line_error(mfilename,'Weighted round robin weights must be integers.')
                    end
                otherwise
                    switch nargin
                        case 3 % no destination specified
                            self.output.outputStrategy{1, class.index}{2} = RoutingStrategy.toType(strategy);
                        case 5
                            destination = par1;
                            probability = par2;
                            self.output.outputStrategy{1, class.index}{2} = RoutingStrategy.toType(strategy);
                            if length(self.output.outputStrategy{1, class.index})<3
                                self.output.outputStrategy{1, class.index}{3}{1} = {destination, probability};
                            else
                                self.output.outputStrategy{1, class.index}{3}{end+1} = {destination, probability};
                            end
                    end
            end
        end

        function bool = hasClassSwitch(self)
            % BOOL = HASCLASSSWITCH()

            bool = isa(self.server,'ClassSwitcher');
        end

        function bool = isStateful(self)
            % BOOL = ISSTATEFUL()

            bool = isa(self,'StatefulNode');
        end

        function bool = isStation(self)
            % BOOL = ISSTATION()

            bool = isa(self,'Station');
        end
    end

    methods(Access = protected)
        % Override copyElement method:
        function clone = copyElement(self)
            % CLONE = COPYELEMENT()

            % Make a shallow copy of all properties
            clone = copyElement@Copyable(self);
            % Make a deep copy of each object
            clone.input = self.input.copy;
            clone.server = self.server.copy;
            clone.output = self.output.copy;
        end
    end

    methods (Access = public)
        function ind = subsindex(self)
            % IND = SUBSINDEX()
            if isempty(self.model.obj)
                ind = double(self.model.getNodeIndex(self.name))-1; % 0 based
            else
                ind = self.model.obj.getNodeIndex(self.obj);
            end
        end

        function V = horzcat(self, varargin)
            % V = HORZCAT(VARARGIN)

            V = zeros(1,length(varargin));
            V(1) = 1+ self.subsindex;
            for v=1:length(varargin)
                V(1+v) = 1+varargin{v}.subsindex;
            end
        end

        function V = vertcat(self, varargin)
            % V = VERTCAT(VARARGIN)

            V = zeros(length(varargin),1);
            V(1) = 1+ self.subsindex;
            for v=1:length(varargin)
                V(1+v) = 1+varargin{v}.subsindex;
            end
        end

        function summary(self)
            % SUMMARY()

            line_printf('\nNode: <strong>%s</strong>',self.getName);
            %self.input.summary;
            %            self.server.summary;
            %            self.output.summary;
        end
    end
end
