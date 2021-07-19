classdef process < BPMN.callableElement
% PROCESS object, as part of a Business Process Modeling Notation (BPMN) model. 
%
% Properties:
% isExecutable:             boolean
% auditing:                 auditing information (cell of string)
% monitoring:               monitoring information (cell of string)
% tasks:                    list of tasks
% sendTasks:                list of send tasks
% receiveTasks:             list of receive tasks
% exclusiveGateways:        list of exlusive gateways
% parallelGateways:         list of parallel gateways
% startEvents:              list of start events 
% endEvents:                list of end events
% intermediateThrowEvents:  list of intermediate throw events
% intermediateCatchEvents:  list of intermediate catch events
% sequenceFlows:            list of sequence flows   
%
% Copyright (c) 2012-2016, Imperial College London 
% All rights reserved.

properties
    isExecutable;           % boolean
    auditing;               % auditing information (cell of string)
    monitoring;             % monitoring information (cell of string)
    
    tasks;                      % list of tasks
    sendTasks;                  % list of send tasks
    receiveTasks;               % list of receive tasks
    exclusiveGateways;          % list of exlusive gateways
    parallelGateways;           % list of parallel gateways
    inclusiveGateways;          % list of inclusive gateways
    startEvents;                % list of start events 
    endEvents;                  % list of end events
    intermediateThrowEvents;    % list of intermediate throw events
    intermediateCatchEvents;    % list of intermediate catch events
    sequenceFlows;              % list of sequence flows   
    laneSet;                    % list of sets of lanes in the process
end

methods
%public methods, including constructor

    %constructor
    function obj = process(id, name, isExecutable)
        if(nargin == 0)
            disp('Not enough input arguments'); 
            id = int2str(rand()); 
        elseif(nargin <= 1)
            disp('Not enough input arguments'); 
            name = ['process_',id];
        end
        obj@BPMN.callableElement(id,name); 
        
        if nargin > 2
            obj.isExecutable = isExecutable;
        else
        end
    end
    
    function obj = addAuditing(obj, audit)
       if nargin > 1
            if isempty(obj.auditing)
                obj.auditing = cell(1);
                obj.auditing{1} = audit;
            else
                obj.auditing{end+1,1} = audit;
            end
       end
    end
    
    function obj = addMonitoring(obj, monit)
       if nargin > 1
            if isempty(obj.auditing)
                obj.monitoring = cell(1);
                obj.monitoring{1} = monit;
            else
                obj.monitoring{end+1,1} = monit;
            end
       end
    end
    
    %% Tasks
    function obj = addTask(obj, task)
        if isempty(obj.tasks)
            obj.tasks = task;
        else
            obj.tasks(end+1,1) = task;
        end
    end
    
    function obj = addSendTask(obj, task)
        if isempty(obj.sendTasks)
            obj.sendTasks = task;
        else
            obj.sendTasks(end+1,1) = task;
        end
    end
    
    function obj = addReceiveTask(obj, task)
        if isempty(obj.receiveTasks)
            obj.receiveTasks = task;
        else
            obj.receiveTasks(end+1,1) = task;
        end
    end
    
    %% Gateways
    function obj = addExclusiveGateway(obj, gateway)
        if isempty(obj.exclusiveGateways)
            obj.exclusiveGateways = gateway;
        else
            obj.exclusiveGateways(end+1,1) = gateway;
        end
    end
    
    function obj = addParallelGateway(obj, gateway)
        if isempty(obj.parallelGateways)
            obj.parallelGateways = gateway;
        else
            obj.parallelGateways(end+1,1) = gateway;
        end
    end
    
    function obj = addInclusiveGateway(obj, gateway)
        if isempty(obj.inclusiveGateways)
            obj.inclusiveGateways = gateway;
        else
            obj.inclusiveGateways(end+1,1) = gateway;
        end
    end
    
    %% Flows
    function obj = addSequenceFlow(obj, flow)
        if isempty(obj.sequenceFlows)
            obj.sequenceFlows = flow;
        else
            obj.sequenceFlows(end+1,1) = flow;
        end
    end
    
     %% Events
    function obj = addStartEvent(obj, startEvent)
        if isempty(obj.startEvents)
            obj.startEvents = startEvent;
        else
            obj.startEvents(end+1,1) = startEvent;
        end
    end
    
    function obj = addEndEvent(obj, event)
        if isempty(obj.endEvents)
            obj.endEvents = event;
        else
            obj.endEvents(end+1,1) = event;
        end
    end
    
    function obj = addIntermediateThrowEvent(obj, event)
        if isempty(obj.intermediateThrowEvents)
            obj.intermediateThrowEvents = event;
        else
            obj.intermediateThrowEvents(end+1,1) = event;
        end
    end
    
    function obj = addIntermediateCatchEvent(obj, event)
        if isempty(obj.intermediateCatchEvents)
            obj.intermediateCatchEvents = event;
        else
            obj.intermediateCatchEvents(end+1,1) = event;
        end
    end
    
    %% lanes sets
    function obj = addLaneSet(obj, laneSet)
       if nargin > 1
            if isempty(obj.laneSet)
                obj.laneSet = laneSet;
            else
                obj.laneSet(end+1,1) = laneSet;
            end
       end
    end
    
     %toString
    function myString = toString(obj)
        myString = toString@BPMN.callableElement(obj);
    end

end
    
end