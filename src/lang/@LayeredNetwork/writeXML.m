function writeXML(self,filename,useAbstractNames)
% WRITEXML(SELF,FILENAME,USEAN)
%
% USEAN: if true replaces node names with abstract names eg E1, T1, ... 
%
% Copyright (c) 2012-2023, Imperial College London
% All rights reserved.

if nargin<3
    useAbstractNames=false;
end
nodeHashMap = containers.Map;

tctr = 0;
ectr = 0;
actr = 0;
if useAbstractNames
    for p = 1:length(self.hosts)
        curProc = self.hosts{p};
        nodeHashMap(curProc.name)=sprintf('P%d',p);
        for t=1:length(curProc.tasks)
            curTask = curProc.tasks(t);
            tctr = tctr + 1;
            nodeHashMap(curTask.name)=sprintf('T%d',tctr);
            for e=1:length(curTask.entries)
                curEntry = curTask.entries(e);
                ectr = ectr + 1;
                nodeHashMap(curEntry.name)=sprintf('E%d',ectr);
            end
            for a=1:length(curTask.activities)
                curAct = curTask.activities(a);
                actr = actr + 1;
                nodeHashMap(curAct.name) = sprintf('A%d',actr);
            end
        end
    end
else
    for p = 1:length(self.hosts)
        curProc = self.hosts{p};
        nodeHashMap(curProc.name)=curProc.name;
        for t=1:length(curProc.tasks)
            curTask = curProc.tasks(t);
            nodeHashMap(curTask.name)=curTask.name;
            for e=1:length(curTask.entries)
                curEntry = curTask.entries(e);
                nodeHashMap(curEntry.name)=curEntry.name;
            end
            for a=1:length(curTask.activities)
                curAct = curTask.activities(a);
                nodeHashMap(curAct.name)=curAct.name;
            end
        end
    end
end

import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.DocumentBuilder;
import org.w3c.dom.Document;
import org.w3c.dom.NodeList;
import org.w3c.dom.Node;
import org.w3c.dom.Element;
import java.io.File;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.dom.DOMSource;
import javax.xml.transform.stream.StreamResult;
import javax.xml.transform.OutputKeys;

precision = '%10.15e'; %precision for doubles
docFactory = DocumentBuilderFactory.newInstance();
docBuilder = docFactory.newDocumentBuilder();
doc = docBuilder.newDocument();

%Root Element
rootElement = doc.createElement('lqn-model');
doc.appendChild(rootElement);
rootElement.setAttribute('xmlns:xsi', 'http://www.w3.org/2001/XMLSchema-instance');
rootElement.setAttribute('xsi:noNamespaceSchemaLocation', 'lqn.xsd');
rootElement.setAttribute('name', getName(self));

for p = 1:length(self.hosts)
    %processor
    curProc = self.hosts{p};
    procElement = doc.createElement('processor');
    rootElement.appendChild(procElement);
    procElement.setAttribute('name', nodeHashMap(curProc.name));
    procElement.setAttribute('scheduling', SchedStrategy.toText(curProc.scheduling));
    if curProc.replication>1
        procElement.setAttribute('replication', num2str(curProc.replication));
    end
    if ~strcmp(curProc.scheduling,SchedStrategy.INF)
        mult = num2str(curProc.multiplicity);
        if isinf(mult), mult=1; end
        procElement.setAttribute('multiplicity', mult);
    end
    if strcmp(curProc.scheduling,SchedStrategy.PS)
        procElement.setAttribute('quantum', num2str(curProc.quantum));
    end
    procElement.setAttribute('speed-factor', num2str(curProc.speedFactor));
    for t=1:length(curProc.tasks)
        curTask = curProc.tasks(t);
        taskElement = doc.createElement('task');
        procElement.appendChild(taskElement);
        taskElement.setAttribute('name', nodeHashMap(curTask.name));
        taskElement.setAttribute('scheduling', SchedStrategy.toText(curTask.scheduling));
        if curTask.replication>1
            taskElement.setAttribute('replication',  num2str(curTask.replication));
        end
        if ~strcmp(curTask.scheduling,SchedStrategy.INF)
            taskElement.setAttribute('multiplicity', num2str(curTask.multiplicity));
        end
        if strcmp(curTask.scheduling,SchedStrategy.REF)
            taskElement.setAttribute('think-time', num2str(curTask.thinkTimeMean));
        end
        for e=1:length(curTask.entries)
            curEntry = curTask.entries(e);
            entryElement = doc.createElement('entry');
            taskElement.appendChild(entryElement);
            entryElement.setAttribute('name', nodeHashMap(curEntry.name));
            entryElement.setAttribute('type', 'NONE');
        end
        taskActsElement = doc.createElement('task-activities');
        taskElement.appendChild(taskActsElement);
        for a=1:length(curTask.activities)
            curAct = curTask.activities(a);
            actElement = doc.createElement('activity');
            taskActsElement.appendChild(actElement);
            actElement.setAttribute('host-demand-mean', num2str(curAct.hostDemandMean));
            actElement.setAttribute('host-demand-cvsq', num2str(curAct.hostDemandSCV));
            if ~isempty(curAct.boundToEntry)
                actElement.setAttribute('bound-to-entry', nodeHashMap(curAct.boundToEntry));
            end
            actElement.setAttribute('call-order', curAct.callOrder);
            actElement.setAttribute('name', nodeHashMap(curAct.name));

            for sc=1:length(curAct.syncCallDests)
                syncCallElement = doc.createElement('synch-call');
                actElement.appendChild(syncCallElement);
                syncCallElement.setAttribute('dest', nodeHashMap(curAct.syncCallDests{sc}));
                syncCallElement.setAttribute('calls-mean', num2str(curAct.syncCallMeans(sc)));
            end
            for ac=1:length(curAct.asyncCallDests)
                asyncCallElement = doc.createElement('asynch-call');
                actElement.appendChild(asyncCallElement);
                asyncCallElement.setAttribute('dest', nodeHashMap(curAct.asyncCallDests{ac}));
                asyncCallElement.setAttribute('calls-mean', num2str(curAct.asyncCallMeans(ac)));
            end
        end
        for ap=1:length(curTask.precedences)
            curActPrec = curTask.precedences(ap);
            actPrecElement = doc.createElement('precedence');
            taskActsElement.appendChild(actPrecElement);

            preElement = doc.createElement(curActPrec.preType);
            actPrecElement.appendChild(preElement);
            if strcmp(curActPrec.preType, ActivityPrecedenceType.PRE_AND) && ~isempty(curActPrec.preParams)
                preElement.setAttribute('quorum', num2str(curActPrec.preParams(1)));
            end
            for pra = 1:length(curActPrec.preActs)
                preActElement = doc.createElement('activity');
                preElement.appendChild(preActElement);
                preActElement.setAttribute('name', nodeHashMap(curActPrec.preActs{pra}));
            end

            postElement = doc.createElement(curActPrec.postType);
            actPrecElement.appendChild(postElement);
            if strcmp(curActPrec.postType, ActivityPrecedenceType.POST_OR)
                for poa = 1:length(curActPrec.postActs)
                    postActElement = doc.createElement('activity');
                    postElement.appendChild(postActElement);
                    postActElement.setAttribute('name', nodeHashMap(curActPrec.postActs{poa}));
                    postActElement.setAttribute('prob', num2str(curActPrec.postParams(poa)));
                end
            elseif strcmp(curActPrec.postType, ActivityPrecedenceType.POST_LOOP)
                for poa = 1:length(curActPrec.postActs)-1
                    postActElement = doc.createElement('activity');
                    postElement.appendChild(postActElement);
                    postActElement.setAttribute('name', nodeHashMap(curActPrec.postActs{poa}));
                    postActElement.setAttribute('count', num2str(curActPrec.postParams(poa)));
                end
                postElement.setAttribute('end', curActPrec.postActs{end});
            else
                for poa = 1:length(curActPrec.postActs)
                    postActElement = doc.createElement('activity');
                    postElement.appendChild(postActElement);
                    postActElement.setAttribute('name', nodeHashMap(curActPrec.postActs{poa}));
                end
            end
        end
        if ~strcmpi(curTask.scheduling, SchedStrategy.REF)
            for e=1:length(curTask.entries)
                curEntry = curTask.entries(e);
                if ~isempty(curEntry.replyActivity)
                    entryReplyElement = doc.createElement('reply-entry');
                    taskActsElement.appendChild(entryReplyElement);
                    entryReplyElement.setAttribute('name', nodeHashMap(curEntry.name));
                    for r=1:length(curEntry.replyActivity)
                        entryReplyActElement = doc.createElement('reply-activity');
                        entryReplyElement.appendChild(entryReplyActElement);
                        entryReplyActElement.setAttribute('name', nodeHashMap(curEntry.replyActivity{r}));
                    end
                end
            end
        end
    end
end

%write the content into xml file
transformerFactory = TransformerFactory.newInstance();
transformer = transformerFactory.newTransformer();
transformer.setOutputProperty(OutputKeys.INDENT, 'yes');
source = DOMSource(doc);
if isempty(fileparts(filename))
    filename=[lineRootFolder,filesep,'workspace',filesep,filename];
end

%if self.options.verbose
%    line_printf('\nLQN model: %s\n', filename);
%end
result = StreamResult(File(filename));
transformer.transform(source, result);
end
