function modelExt = parseXML_BPMNextensions(filename, verbose)
% PARSEXML_BPMNEXTENSIONS(A) parses an XML file A describing extensions to BPMN 
% according to the BPMNextensions schema
%
% Parameters: 
%   doc:          head of the XML object to parse
%   verbose:      1 for screen output 
%
% Output:
%   modelExt:       BPMN extension containing 2 elements:
%   resources:      list of resources to use in the BPMN model
%   taskRes:        list of tasks (column 1), their associated resource (column 2), 
%                   and the index of the assignment in the associated resource (column 3)                
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

import BPMN.resource;

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
        modelExt = [];
        return;
    else 
        rethrow(exception);
    end
end

doc.getDocumentElement().normalize();
if verbose > 0
    disp(['Parsing BPMN Extension file: ', filename ] );
    disp(['Root element:', char(doc.getDocumentElement().getNodeName()) ] );
end


resList = doc.getElementsByTagName('resource');
resources = [];
taskRes = cell(0,3);
for i = 0:resList.getLength()-1
    resNode = resList.item(i);
    if resNode.getNodeType() == Node.ELEMENT_NODE
        resElement = resNode;
        id = char(resElement.getAttribute('id')); 
        name = char(resElement.getAttribute('name')); 
        multiplicity = str2num(char(resElement.getAttribute('multiplicity'))); 
        scheduling = char(resElement.getAttribute('scheduling')); 
        
        myRes = resource(id,name, multiplicity, scheduling); 
        
        assignList = resNode.getElementsByTagName('assignment');
        for j = 0:assignList.getLength()-1
            assignNode = assignList.item(j);
            if assignNode.getNodeType() == Node.ELEMENT_NODE
                assignElement = assignNode;
                taskID = char(assignElement.getAttribute('taskID')); 
                meanExecTime = char(assignElement.getAttribute('meanExecutionTime'));
                myRes = myRes.addAssignment(taskID, meanExecTime); 
                taskRes{end+1,1} = taskID;
                taskRes{end,2} = id;
                taskRes{end,3} = j+1;
            end
        end
        resources = [resources; myRes];
    end
end
modelExt.resources = resources;
modelExt.taskRes = taskRes; 

gateList = doc.getElementsByTagName('exclusiveGateway');
exclusiveGateways = [];
for i = 0:gateList.getLength()-1
    gateNode = gateList.item(i);
    if gateNode.getNodeType() == Node.ELEMENT_NODE
        gateElement = gateNode;
        id = char(gateElement.getAttribute('id')); 
        myGateway.id = id; 
        
        outgoingLinks = cell(0,2); 
        linkList = gateNode.getElementsByTagName('outgoingLink');
        for j = 0:linkList.getLength()-1
            linkNode = linkList.item(j);
            if linkNode.getNodeType() == Node.ELEMENT_NODE
                linkElement = linkNode;
                linkID = char(linkElement.getAttribute('outgoingLinkID')); 
                prob = str2double(char(linkElement.getAttribute('probability')));
                outgoingLinks{end+1,1} = linkID; 
                outgoingLinks{end,2} = prob; 
            end
        end
        myGateway.outgoingLinks = outgoingLinks;
        exclusiveGateways = [exclusiveGateways; myGateway];
    end
end

modelExt.exclusiveGateways = exclusiveGateways;


eventList = doc.getElementsByTagName('startEvent');
startEvents = [];
for i = 0:eventList.getLength()-1
    eventNode = eventList.item(i);
    if eventNode.getNodeType() == Node.ELEMENT_NODE
        eventElement = eventNode;
        id = char(eventElement.getAttribute('id')); 
        myStartEvent.id = id; 
        thinkTime = char(eventElement.getAttribute('meanThinkTime')); 
        myStartEvent.thinkTime = thinkTime; 
        multiplicity = str2double(char(eventElement.getAttribute('multiplicity')));
        myStartEvent.multiplicity = multiplicity; 
        
        myGateway.outgoingLinks = outgoingLinks;
        startEvents = [startEvents; myStartEvent];
    end
end

modelExt.startEvents = startEvents;
