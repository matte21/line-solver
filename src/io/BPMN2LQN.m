function myLQN = BPMN2LQN(bp, bp_ext)

    import BPMN.*;

    if ~isempty(bp) && ~isempty(bp_ext)
        name = bp.name;
        myLQN = LayeredNetwork(name);
        n = length(bp.process);

        hosts = cell(0); %list of hosts - Proc
        tasks = cell(0); %list of tasks - Task, ProcID
        entries = cell(0); %list of entries - Entry, TaskID, ProcID
        activities = cell(0); %list of activities - Act, TaskID, ProcID
        procID = 1;
        taskID = 1;
        entryID = 1;
        actID = 1;
        procObj = cell(0);
        %procObj2 = [];
        taskObj = cell(0);
        entryObj = cell(0);
        actObj = cell(0);


        %% 1. create one LQN processor and task for each resource defined in the  BPMN extension
       
            
        m = length(bp_ext.resources);
        for i = 1:m 
            % processor constructor
            name = bp_ext.resources(i).name;
            multiplicity = bp_ext.resources(i).multiplicity;
            scheduling = bp_ext.resources(i).scheduling; 
            quantum = 1E-3;     % default
            speedFactor = 1;    % default - should remain like this
            replication = 1;    % default 
            newProc = Processor(myLQN, [name,'_processor'], multiplicity, scheduling, quantum, speedFactor);    %D:src\lang\@LayeredNetwork\parseXML.m line77
            newProc.setReplication(replication);
            %newProc.ID = bp_ext.resources(i).id;
            procObj{end+1,1} = newProc;
            %procObj2 = [procObj2; newProc];

            % tasks constructor - default
            %multiplicity = 1;       % default ？In parseXML.m, it says warning when multiplicity is finite and scheduling is inf 
            multiplicity = Inf;     % To match scheduling inf
            scheduling = 'inf';     % default
            thinkTime = 0;          % default
            %activityGraph = 'YES';  % default
            replication = 1;
            newTask = Task(myLQN, [name, '_task'], multiplicity, scheduling, thinkTime);
            newTask.setReplication(replication);
            taskObj{end+1,1} = newTask;

            % create an Entry for each BPMN Task executed by this Resource
            numTasks = size(bp_ext.resources(i).assignments,1);
            for j = 1:numTasks
                newEntry = Entry(myLQN, [bp_ext.resources(i).assignments{j,1}, '_entry']);
                entryObj{end+1,1} = newEntry;
                name = [bp_ext.resources(i).assignments{j,1}, '_activity'];
                %name = [bp_ext.resources(i).assignments{j,1}];
                phase = 1;
                boundToEntry = newEntry.name;
                hostDemandMean = BPMNtime2sec(bp_ext.resources(i).assignments{j,2});
                hostDemandSCV = 1.0;    % default
                callOrder = '';
                newAct = Activity(myLQN, name, hostDemandMean, boundToEntry, callOrder); % default callOrder: STOCHASTIC 
                actObj{end+1,1} = newAct;
                %dest = [bp_ext.resources(i).assignments{j,1}, '_entry'];
                %callsMean = 1; % default
                %newAct = newAct.synchCall(dest, callsMean);
                %newEntry = newEntry.addActivity(newAct);
                activities{end+1,1} = newAct.name;
                activities{end,2} = taskID;
                activities{end,3} = procID;
                newTask = newTask.addActivity(newAct);
                newAct.parent = newTask;
                actID = actID+1;
                
                %reply-entry
                newEntry.replyActivity{1} = name;

                entries{end+1,1} = newEntry.name;
                entries{end,2} = taskID;
                entries{end,3} = procID;
                newTask = newTask.addEntry(newEntry);
                newEntry.parent = newTask;
                entryID = entryID+1;
            end

            tasks{end+1,1} = newTask.name;
            tasks{end,2} = procID;
            newProc = newProc.addTask(newTask);
            taskID = taskID+1;
            
            hosts{end+1,1} = newProc.name;
            procID = procID+1;
        end
        
        

        %% 2. create one LQN processor and task for each BPMN process
        % identify processes that generate workload and those that donot
        refProcesses = zeros(1,n);
        for i = 1:n 
            numSE = length(bp.process(i).startEvents); 
            if numSE == 1 
                refProcesses(i) = 1;
            end
        end

        % buils a list of all messages: ID - sourceProcess - sourceElement - targetProcess - targetElement
        msgList = createMsgList(bp); 
        %disp(msgList);

        % create a request-reply list, specifying, for each request message the corresponding reply message
        reqReply = createReqReplyList(bp, refProcesses, msgList); 
        %disp(reqReply);
        % check there is only one reference process
        if sum(refProcesses) > 1
            % throw exception - more than one start event 
            errID =  'BPMN:NonSupportedFeature:MoreThanOneStartEvent'; 
            errMsg = 'There are %d processes with a start event. Maximum one Process with a Start Event is supported.';
            err = MException(errID, errMsg, sum(refProcesses));
            throw(err)
        elseif sum(refProcesses) < 1
            % throw exception - no start event specified 
            errID =  'BPMN:NonSupportedFeature:NoStartEvent'; 
            errMsg = 'There are no processes with a start event. One Start Event must be specified.';
            err = MException(errID, errMsg);
            throw(err)
        end

        %% 2.a. analyze BPMN processes WITHOUT start events - create entries
        for i = find(refProcesses==0) 
            % indexes of messages that point to this process
            idxMsg = find(cell2mat(msgList(:,4))==i)';
            for j = idxMsg
                % create pseudo task and processor for each incoming message
                if isempty(find(reqReply(:,3)==j,1)) % check that message is NOT a REPLY to this PROCESS (thus not an entry)
                    % processor constructor - default
                    name = [bp.process(i).name, '_MSG_', msgList{j,1}];
                    multiplicity = 1;   % default
                    scheduling = 'inf'; % default
                    quantum = 1E-3;     % default
                    speedFactor = 1;    % default - should remain like this
                    newProc = Processor(myLQN, [name,'_processor'], multiplicity, scheduling, quantum, speedFactor);

                    % tasks constructor - default
                    multiplicity = 1;       % default
                    scheduling = 'inf';     % default
                    thinkTime = 0;          % default
                    %activityGraph = 'YES';  % default
                    newTask = Task(myLQN, [name, '_task'], multiplicity, scheduling, thinkTime);

                    % default entry
                    newEntry = Entry(myLQN, [name, '_entry']);
                    newTask = newTask.addEntry(newEntry);

                    % generate Task Activity graph starting from Element that recives the Message 
                    newTask = generateTaskActivityGraph(bp.process(i), newTask, msgList{j,5}, bp_ext, myLQN, activities, procID, taskID, actID, msgList, reqReply, {bp.process.name}');
                    
                    % add entry to list of entries 
                    entries{end+1,1} = newEntry.name;
                    entries{end,2} = taskID;
                    entries{end,3} = procID;
                    newEntry.parent = newTask;
                    entryID = entryID+1;

                    newProc = newProc.addTask(newTask);
                    % myLQN = myLQN.addProcessor(newProc);

                    tasks{end+1,1} = newTask.name;
                    tasks{end,2} = procID;
                    taskID = taskID+1;
                    
                    hosts{end+1,1} = newProc.name;
                    procID = procID+1;
                end
            end
        end

        %% 2.b. analyze BPMN processes WITH start events
        for i = find(refProcesses==1) 
            % processor constructor - default
            name = bp.process(i).name;
            multiplicity = 1;   % default
            scheduling = 'inf'; % default
            quantum = 1E-3;     % default
            speedFactor = 1;    % default - should remain like this
            newProc = Processor(myLQN, [name, '_processor'], multiplicity, scheduling, quantum, speedFactor); 

            % tasks constructor - default
            multiplicity = 1;       % default
            scheduling = 'ref';     % default
            thinkTime = 0;          % default
            %activityGraph = 'YES';  % default
            newTask = Task(myLQN, [name, '_task'], multiplicity, scheduling, thinkTime);
            newTask.setReplication(replication);
            taskObj{end+1, 1} = newTask;

             % check if current processor has a start event -> reference task (workload)
            numSE = length(bp.process(i).startEvents); 
            if numSE == 1
                % only processes with at most 1 start event are supported *****
                
                if ~isempty(bp_ext.startEvents)
                    
                    idxSE = getIndexCellString({bp_ext.startEvents.id}', bp.process(i).startEvents.id);
                    if idxSE == -1
                        % throw exception - start event not specified 
                        errID =  'BPMN:Extension:StartEventNotDefined'; 
                        errMsg = 'Process %s has a start event %s not defined in the BPMN extension';
                        err = MException(errID, errMsg, bp.process(i).name, bp.process(i).startEvents.id);
                        throw(err)
                    else
                        newTask.multiplicity = bp_ext.startEvents(idxSE).multiplicity;
                        newTask.thinkTime = BPMN.BPMNtime2sec(bp_ext.startEvents(idxSE).thinkTime);
                    end
                else
                    % throw exception - no starstart event not specified 
                    errID =  'BPMN:Extension:NoStartEventsDefined'; 
                    errMsg = 'No Start Events have been defined in the BPMN extension';
                    err = MException(errID, errMsg);
                    throw(err)
                end
                
                % default entry
                newEntry = Entry(myLQN, [bp.process(i).startEvents(1).id, '_entry']);
                entryObj{end+1, 1} = newEntry;
                entries{end+1,1} = newEntry.name;
                entries{end,2} = taskID;
                entries{end,3} = procID;
                newTask = newTask.addEntry(newEntry);
                newEntry.parent = newTask;
                entryID = entryID+1;
                
                
            
                
                % generate Task Activity graph starting from Start Event
                newTask = generateTaskActivityGraph(bp.process(i), newTask, bp.process(i).startEvents(1).id, bp_ext, myLQN, activities, procID, taskID, actID, msgList, reqReply, {bp.process.name}');
                

            else %if numSE > 1
                % throw exception - non supported feature
                errID = 'BPMN:NonSupportedFeature:ManyStartEvents'; 
                errMsg = 'Process %s has %d start events';
                err = MException(errID, errMsg, name, numSE);
                throw(err);
            end

            tasks{end+1,1} = newTask.name;
            tasks{end,2} = procID;
            newProc = newProc.addTask(newTask);
            taskID = taskID+1;
            
            hosts{end+1,1} = newProc.name;
            procID = procID+1;
        end

    else
        if isempty(bp)
            disp('Error: BPMN2LQN - Empty BPMN model');
            myLQN = [];
        end
        if isempty(bp_ext)
            disp('Error: BPMN2LQN - Empty BPMN model extension');
            myLQN = [];
        end
    end
end

function newTask = generateTaskActivityGraph(proc, newTask, initElemID, bp_ext, myLQN, activities, procID, taskID, actID, msgList, reqReply, processNames)
    % Build the task activity graph, including activities, their calls,
    % precedences, 
    %
    % proc:         BPMN process under analysis
    % newTask:       LQN task that represents the BPMN process
    % initElemID:   id of the initial element
    % bp_ext:       BPMN extension
    % myLQN:        lqn model
    % msgList:      list of all messages: ID - sourceProcess - sourceElement - targetProcess - targetElement
    % reqReply:     list of request-reply pairs: originitagin process - output (request) Message - input (reply) Message 
        
    
    % list all flow elements in the process - nx3 string cell: each row
    % with id - type - index within type
    %task-activities
    flowElements = cell(0, 4);
    elementTypes = {'tasks';'sendTasks';'receiveTasks'; 'exclusiveGateways';
        'parallelGateways'; 'inclusiveGateways'; 'startEvents'; 'endEvents';
        'intermediateThrowEvents'; 'intermediateCatchEvents'};
    for k = 1:size(elementTypes,1)
        var = eval(['proc.',elementTypes{k}]);
        if ~isempty(var)
            for j = 1:length(var)
                %disp(var(j));
                flowElements{end+1,1} = var(j).id;
                flowElements{end,2} = elementTypes{k};
                flowElements{end,3} = int2str(j);
                flowElements{end,4} = var(j).name;
            end
        end
    end
    %disp("All elements in this example:");
    %disp(flowElements);
    % list of links in the process - nx3 sring cell, each row with id -
    % source - target
    links = cell(length(proc.sequenceFlows),3);
    for k = 1:length(proc.sequenceFlows)
        links{k,1} = proc.sequenceFlows(k).id; 
        links{k,2} = proc.sequenceFlows(k).sourceRef; 
        links{k,3} = proc.sequenceFlows(k).targetRef; 
    end

    currFlowElement = initElemID;
    currIdx = getIndexCellString(flowElements(:,1), currFlowElement);
    n = size(flowElements,1);

    idxChecked = zeros(n,1);  % 0-1 vector, 1 for a checked flow element
    idxToCheck = zeros(n,1);  % 0-1 vector, 1 for a flow element discovered but not checked
    idxToCheck(currIdx) = 1;
    startPoint = 1;
    
    preTypes = {ActivityPrecedence.PRE_SEQ,ActivityPrecedence.PRE_AND,ActivityPrecedence.PRE_OR};
    postTypes = {ActivityPrecedence.POST_SEQ,ActivityPrecedence.POST_AND,ActivityPrecedence.POST_OR,ActivityPrecedence.POST_LOOP};
        
    while sum(idxChecked) < n
        currIdx = find(idxToCheck,1);
        currType = flowElements{currIdx,2};
        currElement = eval(['proc.',currType,'(',flowElements{currIdx,3},')']);
        name = [currElement.id];
        hostDemandMean = 0;
        boundToEntry = '';
        if startPoint == 1
            if strcmp(currType,'startEvents')
                boundToEntry = [currElement.id, '_entry'];
            else
                idxMsg = getIndexCellString(msgList(:,5), currElement.id);
                boundToEntry = [proc.name, '_MSG_', msgList{idxMsg,1},'_entry'];
            end
            startPoint = 0;
        end
        newAct = Activity(myLQN, name, hostDemandMean, boundToEntry);

         % add direct calls to resources 
        if strcmp(currType,'tasks') || strcmp(currType,'sendTasks') || strcmp(currType,'receiveTasks') 
            % find task if listed in the extension
            idxTask = getIndexCellString(bp_ext.taskRes(:,1), currElement.id);
            if idxTask > 0
                % find the resource description in the extension 
                idxRes = getIndexCellString({bp_ext.resources.id}', bp_ext.taskRes{idxTask,2}); 
                if idxRes == -1
                    % throw exception - specified resource not found in extension
                    errID = 'BPMN:Extension:ResourceNotDefined'; 
                    errMsg = 'Resource %s used by task %s not specified in the extension.';
                    err = MException(errID, errMsg, bp_ext.taskRes{idxTask,2}, currElement.id);
                    throw(err)
                else                                 
                    % set call in the activity
                    dest = [currElement.id, '_entry'];
                    callsMean = 1;
                    newAct = newAct.synchCall(dest, callsMean);
                end
            end
        end
        % add synchCall only for send messages, not for reply messages
        if strcmp( currType, 'sendTasks') || strcmp( currType, 'intermediateThrowEvents')
            idxMsgOut = getIndexCellString(msgList(:,3), currElement.id); % index of the message sent 
            idxMsgIn = reqReply(find(reqReply(:,2)==idxMsgOut,1),3); % index of the reply message 
            if ~isempty(idxMsgIn)
                procname = cell2mat(msgList(idxMsgOut,6));
                receivename = cell2mat(msgList(idxMsgOut,1));
                dest = [procname,'_MSG_', receivename, '_entry'];
                callsMean = 1;
                newAct = newAct.synchCall(dest, callsMean);
            end
        end
        activities{end+1,1} = newAct.name;
        activities{end,2} = taskID;
        activities{end,3} = procID;
        newTask = newTask.addActivity(newAct);
        newAct.parent = newTask;
        actID = actID+1;
        

        % precedence
        outLinks = currElement.outgoing;
        m_out = size(outLinks,1); 
        inLinks = currElement.incoming; 
        m_in = size(inLinks,1);

        posts = cell(m_out,1); 
        pres = cell(m_in,1);         

        if m_in  > 1
            if strcmp(currType, 'parallelGateways')
                preType = preTypes{2};
            else
                preType = preTypes{3};
            end
            
            preParams = [];
            for j = 1:m_in
                inLinkIdx = getIndexCellString(links(:,1), inLinks{j});
                % index of source node 
                inIdx = getIndexCellString(flowElements(:,1), links{inLinkIdx,2});
                pres{j} = flowElements{inIdx,1};
            end  
            posts{1} = flowElements{currIdx,1};
            postType = postTypes{1};
            postParams = [];

            newPrec = ActivityPrecedence(pres, posts, preType, postType, preParams, postParams);
            newTask = newTask.addPrecedence(newPrec);
        end


        for j = 1:m_out
            outLinkIdx = getIndexCellString(links(:,1), outLinks{j});
            % index of target node 
            outIdx = getIndexCellString(flowElements(:,1), links{outLinkIdx,3});
            posts{j} = flowElements{outIdx,1};
            % add out nodes not checked yet to list of nodes to check 
            if idxToCheck(outIdx) == 0 && idxChecked(outIdx) == 0 
                idxToCheck(outIdx) = 1; 
            end
        end
        % connect elements that submit messages to the elements that
        % receive the reply (as output element)
        if strcmp( currType, 'sendTasks') || strcmp( currType, 'intermediateThrowEvents')
            idxMsgOut = getIndexCellString(msgList(:,3), currElement.id); % index of the message sent 
            idxMsgIn = reqReply(find(reqReply(:,2)==idxMsgOut,1),3); % index of the reply message 
            if ~isempty(idxMsgIn)
                destElem = msgList{idxMsgIn, 5 }; % id of the element that receives the reply message
                destElemIdx = getIndexCellString(flowElements(:,1), destElem); % index of the same element
                % connect current element to destElem
                m_out = 1; 
                posts = {destElem};
                % add out nodes not checked yet to list of nodes to check 
                if idxToCheck(destElemIdx) == 0 && idxChecked(destElemIdx) == 0 
                    idxToCheck(destElemIdx) = 1; 
                end                
            end
        end
        
        pres = cell(1,1);
        pres{1} = flowElements{currIdx,1};
        preType = preTypes{1};
        preParams = [];
        nextType = flowElements{outIdx,2};
        nextElement = eval(['proc.',nextType,'(',flowElements{outIdx,3},')']);
        
        if m_out > 1
            if strcmp(currType, 'exclusiveGateways')
                postType = postTypes{3};
                gateIdx = getIndexCellString({bp_ext.exclusiveGateways.id}', currElement.id);
                for j = 1:m_out
                    elemIdx = getIndexCellString( bp_ext.exclusiveGateways(gateIdx).outgoingLinks(:,1), currElement.outgoing{j});
                    postParams(j) = bp_ext.exclusiveGateways(gateIdx).outgoingLinks{elemIdx,2};
                end
            else % parallelGateways
                postType = postTypes{2};
                postParams = [];
            end
        else
            if strcmp(nextType, 'tasks') && ~isempty(nextElement.loopCharacteristics)
                postType = postTypes{4};
                postParams = nextElement.loopCharacteristics{3};
                posts{1} = flowElements{outIdx,1};
                next_outLinks = nextElement.outgoing;
                next_outLinkIdx = getIndexCellString(links(:,1), next_outLinks{1});
                % index of target node 
                next_outIdx = getIndexCellString(flowElements(:,1), links{next_outLinkIdx,3});
                nnextType = flowElements{next_outIdx,2};
                nnextElement = eval(['proc.',nnextType,'(',flowElements{next_outIdx,3},')']);
                while strcmp(nnextType, 'tasks') && ~isempty(nnextElement.loopCharacteristics) 
                    
                    posts{end+1} = flowElements{next_outIdx,1};
                    % add out nodes not checked yet to list of nodes to check 
                    if idxToCheck(next_outIdx) == 0 && idxChecked(next_outIdx) == 0 
                        idxChecked(next_outIdx) = 1; 
                    end
                    next_outLinks = nnextElement.outgoing;
                    next_outLinkIdx = getIndexCellString(links(:,1), next_outLinks{1});
                    % index of target node 
                    next_outIdx = getIndexCellString(flowElements(:,1), links{next_outLinkIdx,3});
                    nnextType = flowElements{next_outIdx,2};
                    nnextElement = eval(['proc.',nnextType,'(',flowElements{next_outIdx,3},')']);
                end
                %posts{end+1} = flowElements{next_outIdx,1};
                %idxChecked(outIdx) = 1;
                %idxToCheck(outIdx) = 0;
                %if idxToCheck(next_outIdx) == 0 && idxChecked(next_outIdx) == 0 
                        %idxToCheck(next_outIdx) = 1;
                %end
            else
                postType = postTypes{1};
                postParams = [];
            end
        end
        if strcmp(currType, 'tasks') && ~isempty(currElement.loopCharacteristics) && strcmp(nextType, 'tasks') && ~isempty(nextElement.loopCharacteristics)
            posts = [];
        end
        next_in = nextElement.incoming;
        if strcmp(currType, 'sendTasks')
            numNextIn = 1;
        else
            numNextIn = size(next_in,1);
        end
        if numNextIn < 2 && ~isempty(posts)
            newPrec = ActivityPrecedence(pres, posts, preType, postType, preParams, postParams);
            newTask = newTask.addPrecedence(newPrec);
        end

        % check current node 
        idxChecked(currIdx) = 1; 
        idxToCheck(currIdx) = 0; 
        
    end  
end

%%
function msgList = createMsgList(bp) 
    n = length(bp.process); % number of processes
    m = length(bp.messageFlow); % total number of message flows
    msgList = cell(m,6);
    
    % list of all send tasks and intermediate throw events 
    sendElems = [];
    sendProc = [];
    receiveElems = [];
    receiveProc = [];
    for i = 1:n
        if ~isempty(bp.process(i).sendTasks)
            sendElems =     [sendElems;     {bp.process(i).sendTasks.id}'];
        end
        if ~isempty(bp.process(i).intermediateThrowEvents)
            sendElems =     [sendElems;     {bp.process(i).intermediateThrowEvents.id}'];
        end
        sendProc = [sendProc; i*ones(length(bp.process(i).sendTasks) + length(bp.process(i).intermediateThrowEvents),1)];
        
        if ~isempty(bp.process(i).receiveTasks)
            receiveElems =  [receiveElems;  {bp.process(i).receiveTasks.id}'];
        end
        if ~isempty(bp.process(i).intermediateCatchEvents)
            receiveElems =  [receiveElems;  {bp.process(i).intermediateCatchEvents.id}'];
        end
        receiveProc = [receiveProc; i*ones(length(bp.process(i).receiveTasks) + length(bp.process(i).intermediateCatchEvents),1)];
    end

    for i = 1:m
        msgList{i,1} = bp.messageFlow(i).id;
        msgList{i,3} = bp.messageFlow(i).sourceRef;
        msgList{i,5} = bp.messageFlow(i).targetRef;
        
        idxSend = getIndexCellString(sendElems, bp.messageFlow(i).sourceRef); 
        if idxSend == -1
             % throw exception - specified message is not sent by a sendtask or throw event
            errID = 'BPMN:Message:SendElementNotFound'; 
            errMsg = 'Message %s not  sent by a Send Task or Throw Event.';
            err = MException(errID, errMsg, bp.messageFlow(i).id);
            throw(err)
        end
        idxReceive = getIndexCellString(receiveElems, bp.messageFlow(i).targetRef); 
        if idxReceive == -1
             % throw exception - specified message is not sent by a sendtask or throw event
            errID = 'BPMN:Message:ReceiveElementNotFound'; 
            errMsg = 'Message %s not received by a Receive Task or Catch Event.';
            err = MException(errID, errMsg, bp.messageFlow(i).id);
            throw(err)
        end
        
        msgList{i,2} = sendProc(idxSend);
        msgList{i,4} = receiveProc(idxReceive);
        msgList{i,6} = bp.process(receiveProc(idxReceive)).name;
    end
end

%%
function reqReply = createReqReplyList(bp, refProcesses, msgList)
    % msgList: ID - sourceProcess - sourceElement - targetProcess - targetElement

    reqReply = zeros(0,3); % procIdx - outMessage (request) - inputMessage (reply)
    
    for i = find(refProcesses==1) % for each reference process
        for j = find(cell2mat(msgList(:,2))==i) % for messages that are emitted by this process
            destProc = msgList{j,4};
            destElem = msgList{j,5};
            
            reqReply(end+1,1) = i;
            reqReply(end,2) = j;
            reqReply = getReplyRequest(destProc, destElem, 1, bp, msgList, reqReply); 
        end
    end

end

function reqReply = getReplyRequest(startProc, startElem, counter, bp, msgList, reqReply) 
    % determines the message that replies (if any) to the message that
    % points to destProc and destElem. 
    % The result is stored in reqReply, row counter, column 3
    
    % explore the flow element graph of this processor, starting from destElem -  to deter
    proc = bp.process(startProc);
    flowElements = cell(0,3);
    elementTypes = {'tasks';'sendTasks';'receiveTasks';
                    'exclusiveGateways'; 'parallelGateways'; 'inclusiveGateways';
                    'startEvents'; 'endEvents'; 'intermediateThrowEvents'; 'intermediateCatchEvents'}; 
    for k = 1:size(elementTypes,1)
        var = eval(['proc.',elementTypes{k}]);
        if ~isempty(var)
            for j = 1:length(var)
                flowElements{end+1,1} = var(j).id;
                flowElements{end,2} = elementTypes{k};
                flowElements{end,3} = int2str(j);
            end
        end
    end

    % list of links in the process - nx3 sring cell, each row with id -
    % source - target
    links = cell(length(proc.sequenceFlows),3);
    for k = 1:length(proc.sequenceFlows)
        links{k,1} = proc.sequenceFlows(k).id; 
        links{k,2} = proc.sequenceFlows(k).sourceRef; 
        links{k,3} = proc.sequenceFlows(k).targetRef; 
    end

    % choose start event (unique) as first flow element
    %currFlowElement = proc.startEvents(1).id; 
    currFlowElement = startElem; 
    currIdx = getIndexCellString(flowElements(:,1), currFlowElement);
    n = size(flowElements,1); 
    
    idxChecked = zeros(n,1);  % 0-1 vector, 1 for a checked flow element
    idxToCheck = zeros(n,1);  % 0-1 vector, 1 for a flow element discovered but not checked
    idxToCheck(currIdx) = 1;
    
    outputMessages = zeros(n,1);    % identifies elements that generate messages in the current process 
                                    % in connection with the input message
                                    % currently analyzed
    
    %% explore activity graph starting from the startElem                                
    while sum(idxChecked) < n && sum(idxToCheck) > 0
        currIdx = find(idxToCheck,1); 
        %currID = flowElements{currIdx,1}; 
        currType = flowElements{currIdx,2}; 
        currElement = eval(['proc.', currType,'(',flowElements{currIdx,3},')']);
               
        
        % list of outgoing links
        outLinks = currElement.outgoing; 
        m_out = size(outLinks,1); 
        for j = 1:m_out
            outLinkIdx = getIndexCellString(links(:,1), outLinks{j});
            % index of target node 
            outIdx = getIndexCellString(flowElements(:,1), links{outLinkIdx,3}); 
            
            % add out nodes not checked yet to list of nodes to check 
            if idxToCheck(outIdx) == 0 && idxChecked(outIdx) == 0 
                idxToCheck(outIdx) = 1; 
            end
        end
        
        % list of incoming links - only to check for nodes without incoming
        % flows (i.e., intermediate message events)
        inLinks = currElement.incoming; 
        m_in = size(inLinks,1); 
        for j = 1:m_in
            inLinkIdx = getIndexCellString(links(:,1), inLinks{j});
            % index of source node 
            inIdx = getIndexCellString(flowElements(:,1), links{inLinkIdx,2}); 
            
            % add in nodes not checked yet to list of nodes to check 
            if idxToCheck(inIdx) == 0 && idxChecked(inIdx) == 0 
                idxToCheck(inIdx) = 1; 
            end
        end
        
        %% check for elements sending messages 
        if strcmp(currType,'intermediateThrowEvents') || strcmp(currType,'sendTasks') 
            outputMessages(currIdx) = 1; 
        end
        
        %% check current node 
        idxChecked(currIdx) = 1; 
        idxToCheck(currIdx) = 0; 
    end
    
    %% single output message - either back to originating process or error
    if sum(outputMessages)==1
        % find the index of the output message 
        outMsgIdx = getIndexCellString(msgList(:,3), flowElements{outputMessages==1,1} ); 
        % find the process where the exit message is sent to
        destProc = msgList{outMsgIdx, 4}; 
        if destProc == reqReply(counter,1)
            % base case: destProc is the same as the origin of the current msg
            % under analysis -> 
            % set in reqReply the index of the message that replies - leaves
            % the current element
            reqReply(counter,3) = outMsgIdx;
        else 
            % recursion: destProc is different as the process that
            % originated the current message ->
            % execute the same procedure with the called process and
            % element AND, once the reply to the new message is known, call
            % the same procedure on the current Proc to find the replying
            % message
            
            % recursion on process called
            destElem = msgList{outMsgIdx,5};
            reqReply(end+1,1) = startProc;
            reqReply(end,2) = outMsgIdx;
            reqReply = getReplyRequest(destProc, destElem, counter+1, bp, msgList, reqReply); 
            
            % continuation of analysis of the current process, starting
            % from the element where the reply was obtained
            destProc = startProc; 
            destElem = msgList{reqReply(counter+1,3),5};
            reqReply = getReplyRequest(destProc, destElem, counter, bp, msgList, reqReply); 
        end
        
    end

end






        











