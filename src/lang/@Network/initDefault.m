function initDefault(self, nodes)
% INITDEFAULT(NODES)

% open classes empty
% closed classes initialized at ref station
% running jobs are allocated in class id order until all
% servers are busy

%refreshStruct(self);  % we force update of the model before we initialize

sn = self.getStruct(false);
N = sn.njobs';
if nargin < 2
    nodes = 1:self.getNumberOfNodes;
end

for i=nodes
    if sn.isstation(i)
        n0 = zeros(1,length(N));
        s0 = zeros(1,length(N));
        s = sn.nservers(sn.nodeToStation(i)); % allocate
        for r=find(isfinite(N))' % for all closed classes
            if sn.nodeToStation(i) == sn.refstat(r)
                n0(r) = N(r);
            end
            s0(r) = min(n0(r),s);
            s = s - s0(r);
        end
        state_i = State.fromMarginalAndStarted(sn,i,n0(:)',s0(:)');
        switch sn.nodetype(i)
            case NodeType.Cache
                state_i = [state_i, 1:sn.nvars(i)];
            case NodeType.Place
                state_i = 0; % for now PNs are single class
        end
        switch sn.routing(i)
            case RoutingStrategy.ID_RRB
                % start from first connected queue
                state_i = [state_i, find(sn.rt(i,:),1)];
        end
        if isempty(state_i)
            line_error(mfilename,sprintf('Default initialization failed on station %d.',i));
        else
            %state_i = state_i(1,:); % to change: this effectively disables priors
            self.nodes{i}.setState(state_i);
            prior_state_i = zeros(1,size(state_i,1)); prior_state_i(1) = 1;
            self.nodes{i}.setStatePrior(prior_state_i);
        end
    elseif sn.isstateful(i) % not a station
        switch class(self.nodes{i})
            case 'Cache'
                state_i = zeros(1,self.getNumberOfClasses);
                state_i = [state_i, 1:sum(self.nodes{i}.itemLevelCap)];
                self.nodes{i}.setState(state_i);
            case 'Router'
                self.nodes{i}.setState([1]);
            otherwise
                self.nodes{i}.setState([]);
        end
        %line_error(mfilename,'Default initialization not available on stateful node %d.',i);
    end
end

if self.isStateValid % problem with example_initState_2
    self.hasState = true;
else
    line_error(mfilename,'Default initialization failed.');
end
end