classdef Activity < LayeredNetworkElement
    % A stage of service in a Task of a LayeredNetwork.
    %
    % Copyright (c) 2012-2021, Imperial College London
    % All rights reserved.
        
    properties
        hostDemand;
        hostDemandMean;             %double
        hostDemandSCV;              %double
        parent;
        parentName;                 %string
        boundToEntry;               %string 
        callOrder;                  %string \in {'STOCHASTIC', 'DETERMINISTIC'}
        syncCallDests = cell(0);   %string array
        syncCallMeans = [];        %integer array
        asyncCallDests = cell(0);  %string array
        asyncCallMeans = [];       %integer array
    end
    
    methods
        %public methods, including constructor
        
        %constructor
        function obj = Activity(model, name, hostDemand, boundToEntry, callOrder)
            % OBJ = ACTIVITY(MODEL, NAME, HOSTDEMAND, BOUNDTOENTRY, CALLORDER)
            
            if nargin<2 %~exist('name','var')
                line_error(mfilename,'Constructor requires to specify at least a name.');
            end
            obj@LayeredNetworkElement(name);
            
            if nargin<3 %~exist('hostDemand','var')
                hostDemand = Distrib.Zero;
            end
            if nargin<4 %~exist('boundToEntry','var')
                boundToEntry = '';
            end
            if nargin<5 %~exist('callOrder','var')
                callOrder = 'STOCHASTIC';
            end
            
            obj.setHostDemand(hostDemand);
            obj.boundToEntry = boundToEntry;
            obj.setCallOrder(callOrder);
            model.activities{end+1} = obj;
        end
        
        function obj = setParent(obj, parent)
            % OBJ = SETPARENT(OBJ, PARENT)
            
            if isa(parent,'Entry') || isa(parent,'Task')
                obj.parentName = parent.name;
                obj.parent = parent;
            else
                obj.parentName = parent;
                obj.parent = [];
            end
        end
        
        function obj = on(obj, parent)
            % OBJ = ON(OBJ, PARENT)
            
            parent.addActivity(obj);
            obj.parent = parent;
        end
        
        function obj = setHostDemand(obj, hostDemand)
            % OBJ = SETHOSTDEMAND(OBJ, HOSTDEMAND)
            
            if isnumeric(hostDemand)
                if hostDemand <= Distrib.Zero
                    obj.hostDemand = Immediate.getInstance();
                    obj.hostDemandMean = Distrib.Zero;
                    obj.hostDemandSCV = Distrib.Zero;
                else
                    obj.hostDemand = Exp(1/hostDemand);
                    obj.hostDemandMean = hostDemand;
                    obj.hostDemandSCV = 1.0;
                end
            elseif isa(hostDemand,'Distrib')
                obj.hostDemand = hostDemand;
                obj.hostDemandMean = hostDemand.getMean();
                obj.hostDemandSCV = hostDemand.getSCV();
            end
        end
        
        function obj = repliesTo(obj, entry)
            % OBJ = REPLIESTO(OBJ, ENTRY)
            
            if ~isempty(obj.parent)
                switch SchedStrategy.toId(obj.parent.scheduling)
                    case SchedStrategy.ID_REF
                        line_error(mfilename,'Activities in reference tasks cannot reply.');
                    otherwise
                        entry.replyActivity{end+1} = obj.name;
                end
            else
                entry.replyActivity{end+1} = obj.name;
            end
        end
        
        function obj = boundTo(obj, entry)
            % OBJ = BOUNDTO(OBJ, ENTRY)
            
            if isa(entry,'Entry')
                obj.boundToEntry = entry.name;
            elseif ischar(entry)
                obj.boundToEntry = entry;
            else
                line_error(mfilename,'Wrong entry parameter for boundTo method.');
            end
        end
        
        function obj = setCallOrder(obj, callOrder)
            % OBJ = SETCALLORDER(OBJ, CALLORDER)
            
            if strcmpi(callOrder,'STOCHASTIC') || strcmpi(callOrder,'DETERMINISTIC')
                obj.callOrder = upper(callOrder);
            else
                obj.callOrder = 'STOCHASTIC';
            end
        end
        
        %synchCall
        function obj = synchCall(obj, synchCallDest, synchCallMean)
            % OBJ = SYNCHCALL(OBJ, SYNCHCALLDEST, SYNCHCALLMEAN)
            
            if nargin<3 %~exist('synchCallMean','var')
                synchCallMean = 1.0;
            end
            if ischar(synchCallDest)
                obj.syncCallDests{length(obj.syncCallDests)+1} = synchCallDest;
            else % object
                obj.syncCallDests{length(obj.syncCallDests)+1} = synchCallDest.name;
            end
            obj.syncCallMeans = [obj.syncCallMeans; synchCallMean];
        end
        
        %asynchCall
        function obj = asynchCall(obj, asynchCallDest, asynchCallMean)
            % OBJ = ASYNCHCALL(OBJ, ASYNCHCALLDEST, ASYNCHCALLMEAN)
            
            if nargin<3 %~exist('asynchCallMean','var')
                asynchCallMean = 1.0;
            end
            if ischar(asynchCallDest)
                obj.asyncCallDests{length(obj.asyncCallDests)+1} = asynchCallDest;
            else % object
                obj.asyncCallDests{length(obj.asyncCallDests)+1} = asynchCallDest.name;
            end
            obj.asyncCallMeans = [obj.asyncCallMeans; asynchCallMean];
        end
        
    end
    
end