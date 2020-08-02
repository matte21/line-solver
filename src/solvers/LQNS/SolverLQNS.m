classdef SolverLQNS < LayeredNetworkSolver
    % A solver that interfaces the LQNS to LINE.
    %
    % Copyright (c) 2012-2020, Imperial College London
    % All rights reserved.
    
    methods
        function self = SolverLQNS(model, varargin)
            % SELF = SOLVERLQNS(MODEL, VARARGIN)
            
            self@LayeredNetworkSolver(model, mfilename);
            self.setOptions(Solver.parseOptions(varargin, self.defaultOptions));
            if ~SolverLQNS.isAvailable()
                error('SolverLQNS requires the lqns and lqsim commands to be available on the system path. Please visit: http://www.sce.carleton.ca/rads/lqns/');
            end
        end
        
        function runtime = run(self)
            % RUNTIME = RUN()
            % Run the solver
            
            tic;
            options = self.getOptions;
            filename = [tempname,'.lqnx'];
            self.model.writeXML(filename);
            if options.verbose
                ignoreWarn = '';
            else
                ignoreWarn = '-w ';
            end
            switch options.method
                case {'default','lqns'}
                    system(['lqns ',ignoreWarn,' -i ',num2str(options.iter_max),' -Pstop-on-message-loss=false -x ',filename]);
                case {'srvn'}
                    system(['lqns ',ignoreWarn,' -i ',num2str(options.iter_max),' -Playering=srvn -Pstop-on-message-loss=false -x ',filename]);
                case {'exact'}
                    system(['lqns ',ignoreWarn,' -i ',num2str(options.iter_max),' -Pmva=exact -Pstop-on-message-loss=false -x ',filename]);
                case {'srvnexact'}
                    system(['lqns ',ignoreWarn,' -i ',num2str(options.iter_max),' -Playering=srvn -Pmva=exact -Pstop-on-message-loss=false -x ',filename]);
                case {'sim','lqsim'}
                    system(['lqsim ',ignoreWarn,' -A ',num2str(options.samples),',3 -Pstop-on-message-loss=off -x ',filename]);
                case {'lqnsdefault'}
                    system(['lqns ',ignoreWarn,' -x ',filename]);
                otherwise
                    system(['lqns ',ignoreWarn,' -i ',num2str(options.iter_max),' -Pstop-on-message-loss=false -x ',filename]);
            end
            self.parseXMLResults(filename);
            if ~options.keep
                [filepath,name] = fileparts(filename);
                delete([filepath,filesep,name,'*'])
            end
            runtime = toc;
        end
        
        function [QN,UN,RN,TN] = getAvg(self,~,~,~,~)
            % [QN,UN,RN,TN] = GETAVG(SELF,~,~,~,~)
            
            self.run();
            QN = self.result.Avg.QLen;
            UN = self.result.Avg.Util;
            RN = self.result.Avg.RespT;
            TN = self.result.Avg.Tput;
        end   
        
        function [NodeAvgTable,CallAvgTable] = getRawAvgTables(self)
            % [QN,UN,RN,TN] = GETRAWAVGTABLES(SELF,~,~,~,~)
            
            self.run();
            
            Node = categorical(self.model.lqnGraph.Nodes.Node);
            Objects = self.model.lqnGraph.Nodes.Object;
            O = length(Objects);
            NodeType = categorical(O,1);
            for o = 1:O
                NodeType(o,1) = categorical({class(Objects{o})});
            end            
            Utilization = self.result.RawAvg.Nodes.Utilization;
            Phase1Utilization = self.result.RawAvg.Nodes.Phase1Utilization;
            Phase2Utilization = self.result.RawAvg.Nodes.Phase2Utilization;
            Phase1ServiceTime = self.result.RawAvg.Nodes.Phase1ServiceTime;
            Phase2ServiceTime = self.result.RawAvg.Nodes.Phase2ServiceTime;
            Throughput = self.result.RawAvg.Nodes.Throughput;
            ProcWaiting = self.result.RawAvg.Nodes.ProcWaiting;
            ProcUtilization = self.result.RawAvg.Nodes.ProcUtilization;
            NodeAvgTable = Table(Node, NodeType, Utilization, Phase1Utilization,...
                Phase2Utilization, Phase1ServiceTime, Phase2ServiceTime, Throughput,...
                ProcWaiting, ProcUtilization);
            
            CallIndices = find(self.model.lqnGraph.Edges.Type>0);
            EndNodes = self.model.lqnGraph.Edges.EndNodes(CallIndices,:);
            SourceIndices = findnode(self.model.lqnGraph,EndNodes(:,1));
            SourceNode = categorical(self.model.lqnGraph.Nodes.Node(SourceIndices));
            TargetIndices = findnode(self.model.lqnGraph,EndNodes(:,2));
            TargetNode = categorical(self.model.lqnGraph.Nodes.Node(TargetIndices));
            
            CallTypeMap = [CallType.SYNC;CallType.ASYNC;CallType.FWD];
            Type = categorical(CallTypeMap(self.model.lqnGraph.Edges.Type(CallIndices)));
            Waiting = self.result.RawAvg.Edges.Waiting(CallIndices);
            CallAvgTable = Table(SourceNode, TargetNode, Type, Waiting);            
        end
        
        function [result, iterations] = parseXMLResults(self, filename)
            % [RESULT, ITERATIONS] = PARSEXMLRESULTS(FILENAME)
        
            import javax.xml.parsers.*;
            import org.w3c.dom.*;
            import java.io.*;
            
            lqn = self.model.getStruct;            
            lqnGraph = self.model.getGraph;
            numOfNodes = height(lqnGraph.Nodes);
            numOfEdges = height(lqnGraph.Edges);
            Avg.Nodes.Utilization = NaN*ones(numOfNodes,1);
            Avg.Nodes.Phase1Utilization = NaN*ones(numOfNodes,1);
            Avg.Nodes.Phase2Utilization = NaN*ones(numOfNodes,1);
            Avg.Nodes.Phase1ServiceTime = NaN*ones(numOfNodes,1);
            Avg.Nodes.Phase2ServiceTime = NaN*ones(numOfNodes,1);
            Avg.Nodes.Throughput = NaN*ones(numOfNodes,1);
            Avg.Nodes.ProcWaiting = NaN*ones(numOfNodes,1);
            Avg.Nodes.ProcUtilization = NaN*ones(numOfNodes,1);
            Avg.Edges.Waiting = NaN*ones(numOfEdges,1);
            verbose = self.options.verbose;
            
            % init Java XML parser and load file
            dbFactory = DocumentBuilderFactory.newInstance();
            dBuilder = dbFactory.newDocumentBuilder();
            
            [fpath,fname,~] = fileparts(filename);
            resultFilename = [fpath,filesep,fname,'.lqxo'];
            if self.options.verbose 
                fprintf(1,'Parsing LQNS result file: %s\n',resultFilename);
                warning(warning('query'));
            end
            if self.options.keep
                fprintf(1,'LQNS result file available at: %s\n',resultFilename);
            end
            
            doc = dBuilder.parse(resultFilename);
            doc.getDocumentElement().normalize();
            
            %solver-params
            solverParams = doc.getElementsByTagName('solver-params');
            for i = 0:solverParams.getLength()-1
                solverParam = solverParams.item(i);
                result = solverParam.getElementsByTagName('result-general');
                iterations = str2double(result.item(0).getAttribute('iterations'));
            end
            
            procList = doc.getElementsByTagName('processor');
            for i = 0:procList.getLength()-1
                %Element - Host
                procElement = procList.item(i);
                procName = char(procElement.getAttribute('name'));
                %procPos = findstring(lqnGraph.Nodes.Node,procName);                
                procPos = findstring(lqn.names,procName);
                procResult = procElement.getElementsByTagName('result-processor');
                uRes = str2double(procResult.item(0).getAttribute('utilization'));
                Avg.Nodes.ProcUtilization(procPos) = uRes;
                
                taskList = procElement.getElementsByTagName('task');
                for j = 0:taskList.getLength()-1
                    %Element - Task
                    taskElement = taskList.item(j);
                    taskName = char(taskElement.getAttribute('name'));
                    %taskPos = findstring(lqnGraph.Nodes.Node,taskName);
                    taskPos = findstring(lqn.names,taskName);
                    taskResult = taskElement.getElementsByTagName('result-task');
                    uRes = str2double(taskResult.item(0).getAttribute('utilization'));
                    p1uRes = str2double(taskResult.item(0).getAttribute('phase1-utilization'));
                    p2uRes = str2double(taskResult.item(0).getAttribute('phase2-utilization'));
                    tRes = str2double(taskResult.item(0).getAttribute('throughput'));
                    puRes = str2double(taskResult.item(0).getAttribute('proc-utilization'));
                    Avg.Nodes.Utilization(taskPos) = uRes;
                    Avg.Nodes.Phase1Utilization(taskPos) = p1uRes;
                    Avg.Nodes.Phase2Utilization(taskPos) = ifthenelse(isempty(p2uRes),NaN,p2uRes);
                    Avg.Nodes.Throughput(taskPos) = tRes;
                    Avg.Nodes.ProcUtilization(taskPos) = puRes;
                    
                    entryList = taskElement.getElementsByTagName('entry');
                    for k = 0:entryList.getLength()-1
                        %Element - Entry
                        entryElement = entryList.item(k);
                        entryName = char(entryElement.getAttribute('name'));
                        %entryPos = findstring(lqnGraph.Nodes.Node,entryName);
                        entryPos = findstring(lqn.names,entryName);
                        entryResult = entryElement.getElementsByTagName('result-entry');
                        uRes = str2double(entryResult.item(0).getAttribute('utilization'));
                        p1uRes = str2double(entryResult.item(0).getAttribute('phase1-utilization'));
                        p2uRes = str2double(entryResult.item(0).getAttribute('phase2-utilization'));
                        p1stRes = str2double(entryResult.item(0).getAttribute('phase1-service-time'));
                        p2stRes = str2double(entryResult.item(0).getAttribute('phase2-service-time'));
                        tRes = str2double(entryResult.item(0).getAttribute('throughput'));
                        puRes = str2double(entryResult.item(0).getAttribute('proc-utilization'));
                        Avg.Nodes.Utilization(entryPos) = uRes;
                        Avg.Nodes.Phase1Utilization(entryPos) = p1uRes;
                        Avg.Nodes.Phase2Utilization(entryPos) = ifthenelse(isempty(p2uRes),NaN,p2uRes);
                        Avg.Nodes.Phase1ServiceTime(entryPos) = p1stRes;
                        Avg.Nodes.Phase2ServiceTime(entryPos) = ifthenelse(isempty(p2stRes),NaN,p2stRes);
                        Avg.Nodes.Throughput(entryPos) = tRes;
                        Avg.Nodes.ProcUtilization(entryPos) = puRes;
                    end
                    
                    %task-activities
                    taskActsList = taskElement.getElementsByTagName('task-activities');
                    if taskActsList.getLength > 0
                        taskActsElement = taskActsList.item(0);
                        actList = taskActsElement.getElementsByTagName('activity');
                        for l = 0:actList.getLength()-1
                            %Element - Activity
                            actElement = actList.item(l);
                            if strcmp(char(actElement.getParentNode().getNodeName()),'task-activities')
                                actName = char(actElement.getAttribute('name'));
                                %actPos = findstring(lqnGraph.Nodes.Node,actName);
                                actPos = findstring(lqn.names,actName);
                                actResult = actElement.getElementsByTagName('result-activity');
                                uRes = str2double(actResult.item(0).getAttribute('utilization'));
                                stRes = str2double(actResult.item(0).getAttribute('service-time'));
                                tRes = str2double(actResult.item(0).getAttribute('throughput'));
                                pwRes = str2double(actResult.item(0).getAttribute('proc-waiting'));
                                puRes = str2double(actResult.item(0).getAttribute('proc-utilization'));
                                Avg.Nodes.Utilization(actPos) = uRes;
                                Avg.Nodes.Phase1ServiceTime(actPos) = stRes;
                                Avg.Nodes.Throughput(actPos) = tRes;
                                Avg.Nodes.ProcWaiting(actPos) = pwRes;
                                Avg.Nodes.ProcUtilization(actPos) = puRes;
                                
                                %actID = lqnGraph.Nodes.Name{actPos};
                                actID = lqn.names{actPos};
                                %synch-call
                                synchCalls = actElement.getElementsByTagName('synch-call');
                                for m = 0:synchCalls.getLength()-1
                                    callElement = synchCalls.item(m);
                                    destName = char(callElement.getAttribute('dest'));
                                    %destPos = findstring(lqnGraph.Nodes.Node,destName);
                                    destPos = findstring(lqn.names,destName);
                                    destID = lqn.names{destPos};
                                    %callPos = findedge(lqnGraph,actID,destID);
                                    callPos = findstring(lqn.callnames,[actID,'=>',destID])
                                    callResult = callElement.getElementsByTagName('result-call');
                                    wRes = str2double(callResult.item(0).getAttribute('waiting'));
                                    Avg.Edges.Waiting(callPos) = wRes;
                                end
                                %asynch-call
                                asynchCalls = actElement.getElementsByTagName('asynch-call');
                                for m = 0:asynchCalls.getLength()-1
                                    callElement = asynchCalls.item(m);
                                    destName = char(callElement.getAttribute('dest'));
                                    %destPos = findstring(lqnGraph.Nodes.Node,destName);
                                    destPos = findstring(lqn.names,destName);
                                    %destID = lqnGraph.Nodes.Name{destPos};
                                    destID = lqn.name{destPos};
                                    %callPos = findedge(lqnGraph,actID,destID);
                                    callPos = findstring(lqn.callnames,[actID,'->',destID]);
                                    callResult = callElement.getElementsByTagName('result-call');
                                    wRes = str2double(callResult.item(0).getAttribute('waiting'));
                                    Avg.Edges.Waiting(callPos) = wRes;
                                end
                            end
                        end
                    end
                end
            end
            
            self.result.RawAvg = Avg;
            self.result.Avg.QLen = Avg.Nodes.Utilization(:);
            self.result.Avg.Util = Avg.Nodes.ProcUtilization(:);
            self.result.Avg.RespT = Avg.Nodes.Phase1ServiceTime(:);
            self.result.Avg.Tput = Avg.Nodes.Throughput(:);
            result = self.result;
        end
        
    end
    
    methods (Static)
        function [bool, featSupported] = supports(model)
            % [BOOL, FEATSUPPORTED] = SUPPORTS(MODEL)
            
            featUsed = model.getUsedLangFeatures();
            featSupported = SolverFeatureSet;
            featSupported.setTrue({'Sink','Source','Queue',...
                'Coxian','Erlang','Exponential','HyperExp',...
                'Buffer','Server','JobSink','RandomSource','ServiceTunnel',...
                'SchedStrategy_PS','SchedStrategy_FCFS','ClosedClass'});
            bool = true;
            for e=1:model.getNumberOfLayers()
                bool = bool && SolverFeatureSet.supports(featSupported, featUsed{e});
            end
        end
        
        function options = defaultOptions()
            % OPTIONS = DEFAULTOPTIONS()
            options = lineDefaults('LQNS');
        end
        
        function bool = isAvailable()
            % BOOL = ISAVAILABLE()
            
            bool = true;
            if ispc % windows
                [~,ret] = dos('lqns -V -H');
                if containsstr(ret,'not recognized')
                    bool = false;
                end
                if containsstr(ret,'Version 5') || containsstr(ret,'Version 4') ...
                        || containsstr(ret,'Version 3') || containsstr(ret,'Version 2') ...
                        || containsstr(ret,'Version 1')
                    warning('Unsupported LQNS version. LINE requires Version 6.0 or greater.');
                    bool = false;
                end
            else % linux
                [~,ret] = unix('lqns -V -H');
                if containsstr(ret,'command not found')
                    bool = false;
                end
                if containsstr(ret,'Version 5') || containsstr(ret,'Version 4') ...
                        || containsstr(ret,'Version 3') || containsstr(ret,'Version 2') ...
                        || containsstr(ret,'Version 1')
                    warning('Unsupported LQNS version. LINE requires Version 6.0 or greater.');
                    bool = false;
                end
            end
        end
    end
end
