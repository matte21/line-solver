function buildLayers(self)
lqn = self.lqn;
refnode = find(lqn.schedid == SchedStrategy.ID_REF);
%if length(refnode)>1
%    line_error(mfilename,'This solver supports a single reference node.');
%end
self.ensemble = cell(lqn.ntasks,1);
lqn = self.lqn;

%% build one subnetwork for every processor
self.svctmap = cell(lqn.nhosts+lqn.ntasks,1);
self.callresidtmap = cell(lqn.nhosts+lqn.ntasks,1);
self.arvupdmap = cell(lqn.nhosts+lqn.ntasks,1);
self.svcupdmap = cell(lqn.nhosts+lqn.ntasks,1);
self.callupdmap = cell(lqn.nhosts+lqn.ntasks,1);
self.routeupdmap = cell(lqn.nhosts+lqn.ntasks,1);
for hidx = 1:lqn.nhosts
    callers = lqn.tasksof{hidx};
    self.buildLayersRecursive(hidx, callers, true);
end

%% build one subnetwork for every task
for t = 1:lqn.ntasks
    tidx = lqn.tshift + t;
    if ~lqn.isref(tidx) | ~(isempty(find(self.lqn.iscaller(tidx,:), 1)) & isempty(find(self.lqn.iscaller(:,tidx), 1)))  %#ok<OR2,AND2> % ignore isolated tasks and ref tasks
            % obtain the activity graph of each task that calls some entry in t
            [calling_idx, called_entries] = find(lqn.iscaller(:, lqn.entriesof{tidx})); %#ok<ASGLU>
            callers = intersect(lqn.taskidx, unique(calling_idx)');
            if ~isempty(callers) % true if the server is a software task
                self.buildLayersRecursive(tidx, callers, false);
            else
                self.ensemble{tidx} = [];
            end    
    else
        self.ensemble{tidx} = [];
    end
end

self.svcupdmap = cell2mat(self.svcupdmap);
self.callupdmap = cell2mat(self.callupdmap);
self.svctmap = cell2mat(self.svctmap);
self.arvupdmap = cell2mat(self.arvupdmap);
self.callresidtmap = cell2mat(self.callresidtmap);
self.routeupdmap = cell2mat(self.routeupdmap);

% we now calculate the new index of the models after removing the empty
% models associated to 'ref' tasks
emptymodels = cellfun(@isempty,self.ensemble);
self.ensemble(emptymodels) = [];
self.idxhash = [1:length(emptymodels)]' - cumsum(emptymodels);
self.idxhash(emptymodels) = NaN;

%svcupdmap(:,1) = idxmap(svcupdmap(:,1));
%callupdmap(:,1) = idxmap(callupdmap(:,1));
%svctmap(:,1) = idxmap(svctmap(:,1));
%callresidtmap(:,1) = idxmap(callresidtmap(:,1));
%routupdmap(:,1) = idxmap(routupdmap(:,1));

self.model.ensemble = self.ensemble;
end
