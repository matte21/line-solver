classdef JLINE

    % Example:
    % java_network = JLINE.from_line_network(network);
    % jssa = JLINE.get_solver(java_network, 'ssa');

    properties (Constant)
        jar_loc = which('linesolver.jar');
    end

    methods(Static)
        function java_dist = from_line_distribution(line_dist)
            if isa(line_dist, 'Exp')
                java_dist = jline.lang.distributions.Exp(line_dist.getParam(1).paramValue);
            elseif isa(line_dist, 'Erlang')
                java_dist = jline.lang.distributions.Erlang(line_dist.getParam(1).paramValue, line_dist.getParam(2).paramValue);
            elseif isa(line_dist, 'HyperExp')
                java_dist = jline.lang.distributions.HyperExp(line_dist.getParam(1).paramValue, line_dist.getParam(2).paramValue, line_dist.getParam(3).paramValue);
            elseif isa(line_dist, 'Immediate')
                java_dist = jline.lang.distributions.Immediate();
            elseif isa(line_dist, 'Disabled')
                java_dist = jline.lang.distributions.DisabledDistribution();
                return;
            else
                line_error(mfilename,'Distribution not supported by JLINE.');
            end
        end

        function matlab_dist = from_jline_distribution(java_dist)
            if isa(java_dist, 'jline.lang.distributions.Exp')
                matlab_dist = Exp(java_dist.getRate());
            elseif isa(java_dist, 'jline.lang.distributions.Erlang')
                matlab_dist = Erlang(java_dist.getRate(),java_dist.getNumberOfPhases());
            elseif isa(java_dist, 'jline.lang.distributions.Immediate')
                matlab_dist = Immediate();
            elseif isa(java_dist, 'jline.lang.distributions.DisabledDistribution')
                return;
            else
                line_error(mfilename,'Distribution not supported by JLINE.');
            end
        end

        function set_service(line_node, java_node, job_classes)
            if (isa(line_node, 'Sink') || isa(line_node, 'Router') || isa(line_node, 'ClassSwitch') || isa(line_node, 'Fork') || isa(line_node, 'Join'))
                return;
            end

            for n = 1 : length(job_classes)
                if (isa(line_node, 'Queue') || isa(line_node, 'Delay'))
                    matlab_dist = line_node.getService(job_classes{n});
                elseif (isa(line_node, 'Source'))
                    matlab_dist = line_node.getArrivalProcess(n);
                else
                    line_error(mfilename,'Node not supported by JLINE.');
                end
                service_dist = JLINE.from_line_distribution(matlab_dist);

                if (isa(line_node,'Queue') || isa(line_node, 'Delay'))
                    java_node.setService(java_node.getModel().getClasses().get(n-1), service_dist);
                elseif (isa(line_node, 'Source'))
                    java_node.setArrivalDistribution(java_node.getModel().getClasses().get(n-1), service_dist);
                end
            end
        end

        function set_line_service(jline_node, line_node, job_classes, line_classes)
            if (isa(line_node,'Sink'))
                return;
            end
            for n = 1:job_classes.size()
                java_dist = jline_node.getServiceProcess(job_classes.get(n-1));
                matlab_dist = JLINE.from_jline_distribution(java_dist);

                if (isa(jline_node,'jline.lang.nodes.Queue'))
                    line_node.setService(line_classes{n}, matlab_dist);
                elseif (isa(jline_node, 'jline.lang.nodes.Source'))
                    line_node.setArrival(line_classes{n}, matlab_dist);
                else
                    line_error(mfilename,'Node not supported by JLINE.');
                end
            end
        end

        function node_object = from_line_node(line_node, java_network, job_classes)
            if isa(line_node, 'Delay')
                node_object = jline.lang.nodes.Delay(java_network, line_node.getName);
            elseif isa(line_node, 'Queue')
                node_object = jline.lang.nodes.Queue(java_network, line_node.getName, jline.lang.constant.SchedStrategy.FCFS);
                node_object.setNumberOfServers(line_node.getNumberOfServers);
            elseif isa(line_node, 'Source')
                node_object = jline.lang.nodes.Source(java_network, line_node.getName);
            elseif isa(line_node, 'Sink')
                node_object = jline.lang.nodes.Sink(java_network, line_node.getName);
            elseif isa(line_node, 'Router')
                node_object = jline.lang.nodes.Router(java_network, line_node.getName);
            elseif isa(line_node, 'ClassSwitch')
                nClasses = length(line_node.model.classes);
                classMatrix = java.util.HashMap();
                for i = 1:nClasses
                    outputClasses = java.util.HashMap();
                    outClass = java_network.getClasses().get(i-1);
                    for j = 1:nClasses
                        inClass = java_network.getClasses().get(j-1);
                        outputClasses.put(inClass, line_node.server.csFun(i,j,0,0));
                    end
                    classMatrix.put(outClass, outputClasses);
                end
                node_object = jline.lang.nodes.ClassSwitch(java_network, line_node.getName, classMatrix);
            elseif isa(line_node, 'Fork')
                node_object = jline.lang.nodes.Fork(java_network);
            elseif isa(line_node, 'Join')
                node_object = jline.lang.nodes.Join(java_network);
            else
                line_error(mfilename,'Node not supported by JLINE.');
            end
        end

        function node_object = from_jline_node(jline_node, line_network)
            if isa(jline_node, 'jline.lang.nodes.Delay')
                node_object = Delay(line_network, jline_node.getName.toCharArray');
            elseif isa(jline_node, 'jline.lang.nodes.Queue')
                node_object = Queue(line_network, jline_node.getName.toCharArray', SchedStrategy.FCFS);
                node_object.setNumberOfServers(jline_node.getNumberOfServers);
            elseif isa(jline_node, 'jline.lang.nodes.Source')
                node_object = Source(line_network, jline_node.getName.toCharArray');
            elseif isa(jline_node, 'jline.lang.nodes.Sink')
                node_object = Sink(line_network, jline_node.getName.toCharArray');
            elseif isa(jline_node, 'jline.lang.nodes.Router')
                node_object = Router(line_network, jline_node.getName.toCharArray');
            elseif isa(jline_node, 'jline.lang.nodes.ClassSwitch')
                line_error(mfilename,'Node not supported by JLINE.');
            else
                line_error(mfilename,'Node not supported by JLINE.');
            end
        end

        function node_class = from_line_class(line_class, java_network)
            if isa(line_class, 'OpenClass')
                node_class = jline.lang.OpenClass(java_network, line_class.getName);
            elseif isa(line_class, 'ClosedClass')
                node_class = jline.lang.ClosedClass(java_network, line_class.getName, line_class.population, java_network.getNodeByName(line_class.refstat.getName));
            else
                line_error(mfilename,'Class type not supported by JLINE.');
            end
        end

        function node_class = from_jline_class(java_class, line_network)
            if isa(java_class, 'jline.lang.OpenClass')
                node_class = OpenClass(line_network, java_class.getName.toCharArray');
            elseif isa(java_class, 'jline.lang.ClosedClass')
                node_class = ClosedClass(line_network, java_class.getName.toCharArray', line_class.getNumberOfJobs, java_network.getNodeByName(line_class.refstat.getName));
            else
                line_error(mfilename,'Class type not supported by JLINE.');
            end
        end


        function from_line_links(line_network, network_object)
            connections = line_network.getConnectionMatrix();
            [m, n] = size(connections);
            nodes = network_object.getNodes();
            line_nodes = line_network.getNodes;
            classes = network_object.getClasses();
            n_classes = classes.size();
            routing_matrix = jline.lang.RoutingMatrix(classes, nodes);
            line_nodes = line_network.getNodes;
            % [ ] Update to consider different weights/routing for classes
            for i = 1:m
                line_node = line_nodes{i};
                for k = 1:n_classes
                    output_strat = line_node.output.outputStrategy{k};
                    probabilities = output_strat{3};
                    if ~strcmp(output_strat{2}, 'Probabilities') && ~strcmp(output_strat{2}, 'Random');
                        line_error(mfilename, 'Routing Strategy not supported by JLINE');
                    end
                    for j = 1:length(probabilities)
                        dest_idx = line_network.getNodeIndex(probabilities{j}{1}.name);
                        if (connections(i, j) ~= 0)
                                routing_matrix.addConnection(nodes.get(i-1), nodes.get(dest_idx-1), classes.get(k-1), probabilities{j}{2});
                        end
                    end
                end
            end
            network_object.link(routing_matrix);
        end

        function line_network = from_jline_links(line_network, java_network)
            P = line_network.initRoutingMatrix;
            java_nodes = java_network.getNodes();
            n_classes = java_network.getClasses.size();
            n_nodes = java_nodes.size();

            for n = 1 : n_nodes
                java_node = java_nodes.get(n-1);
                output_strategies = java_node.getOutputStrategies();
                n_strategies = output_strategies.size();
                for m = 1 : n_strategies
                    output_strat = output_strategies.get(m-1);
                    dest = output_strat.getDestination();
                    in_idx = java_network.getNodeIndex(java_node)+1;
                    out_idx = java_network.getNodeIndex(dest)+1;
                    if n_classes == 1
                        P{1}(in_idx,out_idx) = output_strat.getProbability();
                    else
                        strat_class = output_strat.getJobClass();
                        class_idx = java_network.getJobClassIndex(strat_class)+1;
                        P{class_idx,class_idx,in_idx,out_idx} = output_strat.getProbability();
                    end
                end
            end
            line_network.link(P);
        end

        function [network_object, ssa] = from_line_network(line_network)
            w = warning;
            warning('off');
            %javarmpath(JLINE.jar_loc);
            %javaaddpath(JLINE.jar_loc);


            warning(w);
            routing_probs = line_network.getRoutingStrategies;
            for n = 1 : length(routing_probs)
                if (routing_probs(n) ~= RoutingStrategy.ID_RAND) && (routing_probs(n) ~= RoutingStrategy.ID_PROB)
                    line_error(mfilename,'Routing strategy not supported by JLINE integration script.');
                end
            end
            try
                network_object = jline.lang.Network(line_network.getName);
            catch
                javaaddpath(which('linesolver.jar'));
                network_object = jline.lang.Network(line_network.getName);
            end
            network_nodes = line_network.getNodes;
            job_classes = line_network.classes;

            java_nodes = {};
            java_classes = {};

            for n = 1 : length(network_nodes)
                if ~isa(network_nodes{n},"ClassSwitch")
                    java_nodes{n} = JLINE.from_line_node(network_nodes{n}, network_object, job_classes);
                end
            end

            for n = 1 : length(job_classes)
                java_classes{n} = JLINE.from_line_class(job_classes{n}, network_object);
            end

            for n = 1 : length(network_nodes)
                if isa(network_nodes{n},"ClassSwitch")
                    java_nodes{n} = JLINE.from_line_node(network_nodes{n}, network_object, job_classes);
                end
            end

            for n = 1: length(java_nodes)
                for m = 1 : length(java_classes)
                    JLINE.set_service(network_nodes{n}, java_nodes{n}, job_classes);
                end
            end

            JLINE.from_line_links(line_network, network_object);
        end

        function [ssa] = SolverSSA(network_object)
            ssa = jline.solvers.ssa.SolverSSA();
            ssa.setOptions().disableResTime = true;
            ssa.compile(network_object);
        end

        function line_network = jline_to_line(java_network)
            %javaaddpath(jar_loc);
            line_network = Network(java_network.getName);
            network_nodes = java_network.getNodes;
            job_classes = java_network.getClasses;

            line_nodes = cell(network_nodes.size);
            line_classes = cell(job_classes.size);


            for n = 1 : network_nodes.size
                if ~isa(line_nodes{n}, 'ClassSwitch')
                    line_nodes{n} = JLINE.from_jline_node(network_nodes.get(n-1), line_network);
                end
            end

            for n = 1 : job_classes.size
                line_classes{n} = JLINE.from_jline_class(job_classes.get(n-1), line_network);
            end

            for n = 1 : network_nodes.size
                if isa(line_nodes{n}, 'ClassSwitch')
                    JLINE.set_line_service(network_nodes.get(n-1), line_nodes{n}, job_classes, line_classes);
                end
            end

            line_network = JLINE.from_jline_links(line_network, java_network);
        end
    end
end
