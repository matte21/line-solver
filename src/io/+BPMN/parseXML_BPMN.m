function [collab, processes] = parseXML_BPMN(filename, verbose)
% PARSEXML_BPMN(A) parses a BPMN file (XML) file A containing a BPMN model in the
% BPMN-DI format
%
% Parameters: 
% filename:     path of the XML file to parse
% verbose:      1 for screen output
% 
% Output: 
% collab:       collaboration object that represents the BPMN model
%
% Copyright (c) 2012-2016, Imperial College London 
% All rights reserved.


import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.DocumentBuilder;
import org.w3c.dom.Document;
import org.w3c.dom.NodeList;
import org.w3c.dom.Node;
import org.w3c.dom.Element;
import java.io.File;

import BPMN.*;

if nargin == 1
    verbose = 0;
end

dbFactory = DocumentBuilderFactory.newInstance();
dBuilder = dbFactory.newDocumentBuilder();
try
    doc = dBuilder.parse(filename);
catch exception %java.io.FileNotFoundException
    if ~exist(filename, 'file')
        disp(['Error: Input XML file ', filename, ' not found']);
        collab = [];
        processes = []; 
        return;
    else 
        rethrow(exception);
    end
end
 
doc.getDocumentElement().normalize();
if verbose > 0
    disp(['Parsing BPMN file: ', filename] );
    disp(['Root element:', char(doc.getDocumentElement().getNodeName()) ] );
end

% check if prefix is necessay for all elements in the xml 
prefix = '';
if strfind(char(doc.getDocumentElement().getNodeName()), 'semantic:')
    prefix = 'semantic:';
end
    
% collaboration - process - events (start, end) - task - gateways
% (exclusive) - sequenceFlow - 

%% read collaboration
collabList = doc.getElementsByTagName([prefix,'collaboration']);
collab = [];
for i = 0:collabList.getLength()-1
    collabNode = collabList.item(i);
    if collabNode.getNodeType() == Node.ELEMENT_NODE
        collabElement = collabNode;
        id = char(collabElement.getAttribute('id')); 
        name = char(collabElement.getAttribute('name')); 
        collab = collaboration(id, name); 

        % participant
        partList = collabNode.getElementsByTagName([prefix,'participant']);
        for j = 0:partList.getLength()-1
            partNode = partList.item(j);
            if partNode.getNodeType() == Node.ELEMENT_NODE
                partElement = partNode;
                id = char(partElement.getAttribute('id')); 
                name = char(partElement.getAttribute('name')); 
                processRef = char(partElement.getAttribute('processRef')); 
                tempPart = participant(id, name, processRef); 
                collab = collab.addParticipant(tempPart);
            end
        end
        
        % messageFlow
        messageList = collabNode.getElementsByTagName([prefix,'messageFlow']);
        for j = 0:messageList.getLength()-1
            messageNode = messageList.item(j);
            if messageNode.getNodeType() == Node.ELEMENT_NODE
                messageElement = messageNode;
                id = char(messageElement.getAttribute('id')); 
                name = char(messageElement.getAttribute('name')); 
                messageRef = char(messageElement.getAttribute('messageRef')); 
                sourceRef = char(messageElement.getAttribute('sourceRef')); 
                targetRef = char(messageElement.getAttribute('targetRef')); 
                tempMsgFlow = messageFlow(id, name, messageRef,sourceRef,targetRef); 
                collab = collab.addMessageFlow(tempMsgFlow);
            end
        end
    end
end

% if no collaboration is defined, create a default one to add the one
% process part of the collaboration
if isempty(collab) 
    id = 'collab_default';
    name = 'collab_default';
    collab = collaboration(id, name); 
end

%% read messages
messageList = doc.getElementsByTagName([prefix,'message']);
messages = [];
for i = 0:messageList.getLength()-1
    messageNode = messageList.item(i);
    if messageNode.getNodeType() == Node.ELEMENT_NODE
        messageElement = messageNode;
        id = char(messageElement.getAttribute('id')); 
        tempMsg = message(id);
        messages = [messages; tempMsg];
    end
end


%% read processors
procList = doc.getElementsByTagName([prefix,'process']);
processes = [];
for i = 0:procList.getLength()-1
    procNode = procList.item(i);
    if procNode.getNodeType() == Node.ELEMENT_NODE
        procElement = procNode;
        id = char(procElement.getAttribute('id')); 
        name = char(procElement.getAttribute('name')); 
        isExec = char(procElement.getAttribute('isExecutable')); 
        tempProc = process(id, name, isExec); 
        
        
        %% read events
        % read start events
        startEvList = procNode.getElementsByTagName([prefix,'startEvent']);
        for j = 0:startEvList.getLength()-1
            startEvNode = startEvList.item(j);
            if startEvNode.getNodeType() == Node.ELEMENT_NODE
                startEvElement = startEvNode;
                id = char(startEvElement.getAttribute('id')); 
                name = char(startEvElement.getAttribute('name')); 
                tempStartEvent = startEvent(id, name); 
                tempStartEvent = addOutFlows(tempStartEvent, startEvNode, prefix);
                tempStartEvent = addEventDefinitions(tempStartEvent, startEvNode, prefix);
                
                tempProc = tempProc.addStartEvent(tempStartEvent);
            end
        end
        
         % read stop events
        stopEvList = procNode.getElementsByTagName([prefix,'endEvent']);
        for j = 0:stopEvList.getLength()-1
            stopEvNode = stopEvList.item(j);
            if stopEvNode.getNodeType() == Node.ELEMENT_NODE
                stopEvElement = stopEvNode;
                id = char(stopEvElement.getAttribute('id')); 
                name = char(stopEvElement.getAttribute('name')); 
                tempEndEvent = endEvent(id, name); 
                tempEndEvent = addOutFlows(tempEndEvent, stopEvNode, prefix);
                tempEndEvent = addInFlows(tempEndEvent, stopEvNode, prefix);
                tempEndEvent = addEventDefinitions(tempEndEvent, stopEvNode, prefix);
                
                tempProc = tempProc.addEndEvent(tempEndEvent);
            end
        end
        
        % read intermediate throw events
        interEvList = procNode.getElementsByTagName([prefix,'intermediateThrowEvent']);
        for j = 0:interEvList.getLength()-1
            interEvNode = interEvList.item(j);
            if interEvNode.getNodeType() == Node.ELEMENT_NODE
                interEvElement = interEvNode;
                id = char(interEvElement.getAttribute('id')); 
                name = char(interEvElement.getAttribute('name')); 
                tempInterEvent = intermediateThrowEvent(id, name); 
                tempInterEvent = addOutFlows(tempInterEvent, interEvNode, prefix);
                tempInterEvent = addInFlows(tempInterEvent, interEvNode, prefix);
                tempInterEvent = addEventDefinitions(tempInterEvent, interEvNode, prefix);
                
                tempProc = tempProc.addIntermediateThrowEvent(tempInterEvent);
            end
        end
        
        % read intermediate catch events
        interEvList = procNode.getElementsByTagName([prefix,'intermediateCatchEvent']);
        for j = 0:interEvList.getLength()-1
            interEvNode = interEvList.item(j);
            if interEvNode.getNodeType() == Node.ELEMENT_NODE
                interEvElement = interEvNode;
                id = char(interEvElement.getAttribute('id')); 
                name = char(interEvElement.getAttribute('name')); 
                tempInterEvent = intermediateCatchEvent(id, name); 
                tempInterEvent = addOutFlows(tempInterEvent, interEvNode, prefix);
                tempInterEvent = addInFlows(tempInterEvent, interEvNode, prefix);
                tempInterEvent = addEventDefinitions(tempInterEvent, interEvNode, prefix);
                
                tempProc = tempProc.addIntermediateCatchEvent(tempInterEvent);
            end
        end
        
        
        %% read tasks
        % read tasks 
        taskList = procNode.getElementsByTagName([prefix,'task']);
        for j = 0:taskList.getLength()-1
            taskNode = taskList.item(j);
            if taskNode.getNodeType() == Node.ELEMENT_NODE
                taskElement = taskNode;
                id = char(taskElement.getAttribute('id')); 
                name = char(taskElement.getAttribute('name')); 
                tempTask = task(id, name); 
                tempTask = addOutFlows(tempTask, taskNode, prefix);
                tempTask = addInFlows(tempTask, taskNode, prefix);
                
                tempProc = tempProc.addTask(tempTask);
            end
        end
        
        % read send tasks 
        taskList = procNode.getElementsByTagName([prefix,'sendTask']);
        for j = 0:taskList.getLength()-1
            taskNode = taskList.item(j);
            if taskNode.getNodeType() == Node.ELEMENT_NODE
                taskElement = taskNode;
                id = char(taskElement.getAttribute('id')); 
                name = char(taskElement.getAttribute('name')); 
                implementation = char(taskElement.getAttribute('implementation')); 
                tempTask = sendTask(id, name, implementation); 
                tempTask = addOutFlows(tempTask, taskNode, prefix);
                tempTask = addInFlows(tempTask, taskNode, prefix);

                tempProc = tempProc.addSendTask(tempTask);
            end
        end
        
        % read receive tasks 
        taskList = procNode.getElementsByTagName([prefix,'receiveTask']);
        for j = 0:taskList.getLength()-1
            taskNode = taskList.item(j);
            if taskNode.getNodeType() == Node.ELEMENT_NODE
                taskElement = taskNode;
                id = char(taskElement.getAttribute('id')); 
                name = char(taskElement.getAttribute('name')); 
                implementation = char(taskElement.getAttribute('implementation')); 
                tempTask = receiveTask(id, name, implementation); 
                tempTask = addOutFlows(tempTask, taskNode, prefix);
                tempTask = addInFlows(tempTask, taskNode, prefix);

                tempProc = tempProc.addReceiveTask(tempTask);
            end
        end
        
        %% read gateways
        % read exclusive gateways
        gateList = procNode.getElementsByTagName([prefix,'exclusiveGateway']);
        for j = 0:gateList.getLength()-1
            gateNode = gateList.item(j);
            if gateNode.getNodeType() == Node.ELEMENT_NODE
                gateElement = gateNode;
                id = char(gateElement.getAttribute('id')); 
                name = char(gateElement.getAttribute('name')); 
                tempGate = exclusiveGateway(id, name); 
                tempGate = addOutFlows(tempGate, gateNode, prefix);
                tempGate = addInFlows(tempGate, gateNode, prefix);
                
                tempProc = tempProc.addExclusiveGateway(tempGate);
            end
        end
        
        % read parallel gateways
        gateList = procNode.getElementsByTagName([prefix,'parallelGateway']);
        for j = 0:gateList.getLength()-1
            gateNode = gateList.item(j);
            if gateNode.getNodeType() == Node.ELEMENT_NODE
                gateElement = gateNode;
                id = char(gateElement.getAttribute('id')); 
                name = char(gateElement.getAttribute('name')); 
                tempGate = parallelGateway(id, name); 
                tempGate = addOutFlows(tempGate, gateNode, prefix);
                tempGate = addInFlows(tempGate, gateNode, prefix);
                
                tempProc = tempProc.addParallelGateway(tempGate);
            end
        end
        
        % read inclusive gateways
        gateList = procNode.getElementsByTagName([prefix,'inclusiveGateway']);
        for j = 0:gateList.getLength()-1
            gateNode = gateList.item(j);
            if gateNode.getNodeType() == Node.ELEMENT_NODE
                gateElement = gateNode;
                id = char(gateElement.getAttribute('id')); 
                name = char(gateElement.getAttribute('name')); 
                tempGate = inclusiveGateway(id, name); 
                tempGate = addOutFlows(tempGate, gateNode, prefix);
                tempGate = addInFlows(tempGate, gateNode, prefix);
                
                tempProc = tempProc.addInclusiveGateway(tempGate);
            end
        end
        
       
        
        % read sequence flows
        flowList = procNode.getElementsByTagName([prefix,'sequenceFlow']);
        for j = 0:flowList.getLength()-1
            flowNode = flowList.item(j);
            if flowNode.getNodeType() == Node.ELEMENT_NODE
                flowElement = flowNode;
                id = char(flowElement.getAttribute('id')); 
                name = char(flowElement.getAttribute('name')); 
                source = char(flowElement.getAttribute('sourceRef')); 
                target = char(flowElement.getAttribute('targetRef')); 
                
                tempFlow = sequenceFlow(id, name, source, target); 
                
                % get conditional expression 
                expList = flowNode.getElementsByTagName([prefix,'conditionExpression']); 
                if expList.getLength() == 1
                    expNode = expList.item(0);
                    if expNode.getNodeType() == Node.ELEMENT_NODE
                        expElement = expNode;
                        id = char(expElement.getAttribute('id')); 
                        type = char(expElement.getAttribute('xsi:type')); 
                        value = char(expElement.getTextContent); 
                        tempFlow = tempFlow.addCondExpression(id,type,value); 
                    end
                end
                tempProc = tempProc.addSequenceFlow(tempFlow);
            end
        end
        
        %% read lane sets and lanes
        % read lane sets 
        laneSetList = procNode.getElementsByTagName([prefix,'laneSet']);
        for j = 0:laneSetList.getLength()-1
            laneSetNode = laneSetList.item(j);
            if laneSetNode.getNodeType() == Node.ELEMENT_NODE
                laneSetElement = laneSetNode;
                id = char(laneSetElement.getAttribute('id')); 
                name = char(laneSetElement.getAttribute('name')); 
                tempLaneSet = laneSet(id, name); 
                
                % read lanes 
                laneList = laneSetNode.getElementsByTagName([prefix,'lane']);
                for k = 0:laneList.getLength()-1
                    laneNode = laneList.item(k);
                    if laneNode.getNodeType() == Node.ELEMENT_NODE
                        laneElement = laneNode;
                        id = char(laneElement.getAttribute('id')); 
                        name = char(laneElement.getAttribute('name')); 
                        tempLane = lane(id, name); 
                        tempLane = addFlowNodeRef(tempLane, laneNode, prefix);
                        
                        tempLaneSet = tempLaneSet.addLane(tempLane);
                    end
                end
                tempProc = tempProc.addLaneSet(tempLaneSet);
            end
        end
        
    end
    
    processes = [processes; tempProc];
    collab = collab.addProcess(tempProc);
end



end


%% add outgoing flows to a flow node
function tempObj = addOutFlows(tempObj, node, prefix) 
    import org.w3c.dom.Node;
    import BPMN.*;

    % get outgoing 
    outList = node.getElementsByTagName([prefix,'outgoing']); 
    for j = 0:outList.getLength()-1
        outNode = outList.item(j);
        if outNode.getNodeType() == Node.ELEMENT_NODE
            outElement = outNode;
            flow = char(outElement.getTextContent); 
            %prob = str2num(char(transitElement.getAttribute('Probability'))); 
            tempObj = tempObj.addOutgoing(flow); 
        end
    end
end

%% add incoming flows to a flow node
function tempObj = addInFlows(tempObj, node, prefix) 
    import org.w3c.dom.Node;
    import BPMN.*;

    % get incoming
    inList = node.getElementsByTagName([prefix,'incoming']); 
    for j = 0:inList.getLength()-1
        inNode = inList.item(j);
        if inNode.getNodeType() == Node.ELEMENT_NODE
            inElement = inNode;
            flow = char(inElement.getTextContent); 
            tempObj = tempObj.addIncoming(flow); 
        end
    end
end

%% add flow node referefences
function tempObj = addFlowNodeRef(tempObj, node, prefix) 
    import org.w3c.dom.Node;
    import BPMN.*;

    flowNodeList = node.getElementsByTagName([prefix,'flowNodeRef']); 
    for j = 0:flowNodeList.getLength()-1
        flowNodeNode = flowNodeList.item(j);
        if flowNodeNode.getNodeType() == Node.ELEMENT_NODE
            flowNodeElement = flowNodeNode;
            flowNode = char(flowNodeElement.getTextContent); 
            tempObj = tempObj.addFlowNodeRef(flowNode); 
        end
    end
end



%% add event definitions to an event
function tempEv = addEventDefinitions(tempEv, node, prefix) 
    eventTypeList = {   'message';
                        'timer'};
    for i = 1:size(eventTypeList,1)
        tempEv = addEventDefinitionsType(tempEv, node, eventTypeList{i}, prefix);
    end
end

function tempEv = addEventDefinitionsType(tempEv, node, type, prefix) 
    import org.w3c.dom.Node;
    import BPMN.*;

    % get message event definitions 
    eventDefList = node.getElementsByTagName([prefix,type,'EventDefinition']); 
    for j = 0:eventDefList.getLength()-1
        eventDefNode = eventDefList.item(j);
        if eventDefNode.getNodeType() == Node.ELEMENT_NODE
            eventDefElement = eventDefNode;
            id = char(eventDefElement.getAttribute('id')); 
            eventDef = [];
            switch type
                case 'message'
                    eventDef = messageEventDefinition(id);
                    mesRef = char(eventDefElement.getAttribute('messageRef')); 
                    if ~isempty(mesRef)
                        eventDef = eventDef.setMessageRef(mesRef); 
                    end
                    operRef = char(eventDefElement.getAttribute('operationRef')); 
                    if ~isempty(operRef)
                        eventDef = eventDef.setOperationRef(operRef);
                    end
                    
                case 'timer'
                    eventDef = timerEventDefinition(id); 
                    % find elements for time duration, cycle and date
                    timeDurList = node.getElementsByTagName([prefix,'timeDuration']); 
                    timeCycleList = node.getElementsByTagName([prefix,'timeCycle']); 
                    timeDateList = node.getElementsByTagName([prefix,'timeDate']); 
                    if timeDurList.getLength() == 1
                        timeDurNode = timeDurList.item(0);
                        if timeDurNode.getNodeType() == Node.ELEMENT_NODE
                            timeDur = char(timeDurNode.getTextContent); 
                            eventDef = eventDef.setTimeDuration(timeDur);
                        end
                    elseif timeCycleList.getLength() == 1
                        timeCycleNode = timeCycleList.item(0);
                        if timeCycleNode.getNodeType() == Node.ELEMENT_NODE
                            timeCycle = char(timeCycleNode.getTextContent); 
                            eventDef = eventDef.setTimeCycle(timeCycle);
                        end
                    elseif timeDateList.getLength() == 1
                        timeDateNode = timeDateList.item(0);
                        if timeDateNode.getNodeType() == Node.ELEMENT_NODE
                            timeDate = char(timeDateNode.getTextContent); 
                            eventDef = eventDef.setTimeDate(timeDate);
                        end
                    end
                    
            end
            if isempty(eventDef)
                disp(['Unsupported event definition: ', type]);
            else
                tempEv = tempEv.addEventDefinition(eventDef, type); 
            end
        end
    end
    
    
end