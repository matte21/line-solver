function updatePopulations(self, it)
% Update the populations in each layer to address interlocking
lqn = self.lqn;
ilscaling = ones(lqn.nhosts+ lqn.ntasks,lqn.nhosts+ lqn.ntasks); % interlock scaling factors

for step = 1:self.nlayers
    for h=1:lqn.nhosts
        hidx = h;
        ilscaling(hidx) = 1.0;
        if ~lqn.isref(hidx)
            % the following are remote (indirect) callers that certain to be
            % callers of task t, hence if they have multiplicity m then task t
            % cannot have as a matter of fact multiplicity more than m
            callers = lqn.tasksof{hidx};
            multcallers = sum(self.njobsorig(callers,hidx));
            step_callers = find(self.ptaskcallers_step{step}(hidx,:));
            multremote = 0;
            for remidx=step_callers(:)'
                %                multremote = multremote + self.ptaskcallers_step{step}(hidx,remidx)*max(self.njobsorig(remidx,:));
                if lqn.schedid(remidx) == SchedStrategy.ID_INF % first we consider the update where t is an infinite server
                    multremote = multremote + self.ptaskcallers_step{step}(hidx,remidx)*self.util(remidx);
                else
                    multremote = multremote + self.ptaskcallers_step{step}(hidx,remidx)*self.util(remidx)*lqn.mult(remidx);
                end
            end
            if multcallers > multremote && multremote >0 && ~isinf(multremote)
                %[multcallers, multremote]
                % we spread the scaling proportionally to the direct
                % caller probabilities
                caller_spreading_ratio = self.ptaskcallers(hidx,callers);
                caller_spreading_ratio = caller_spreading_ratio/sum(caller_spreading_ratio);
                for c=callers
                    ilscaling(c,hidx) = min(ilscaling(c,hidx), multremote / multcallers .* caller_spreading_ratio(find(c==callers)));
                end
            end
        end
    end

    for t=1:lqn.ntasks
        tidx = lqn.tshift + t;
        if ~lqn.isref(tidx)
            % the following are remote (indirect) callers that certain to be
            % callers of task t, hence if they have multiplicity m then task t
            % cannot have as a matter of fact multiplicity more than m
            [calling_idx, called_entries] = find(lqn.iscaller(:, lqn.entriesof{tidx})); %#ok<ASGLU>
            callers = intersect(lqn.tshift+(1:lqn.ntasks), unique(calling_idx)');
            multcallers = sum(self.njobsorig(callers,tidx));
            step_callers = find(self.ptaskcallers_step{step}(tidx,:)); % caller at step hops from the node
            multremote = 0;
            for remidx=step_callers(:)'
                % multremote = multremote + self.ptaskcallers_step{step}(tidx,remidx)*max(self.njobsorig(remidx,:));
                if lqn.schedid(remidx) == SchedStrategy.ID_INF % first we consider the update where t is an infinite server
                    multremote = multremote + self.ptaskcallers_step{step}(hidx,remidx)*self.util(remidx);
                else
                    multremote = multremote + self.ptaskcallers_step{step}(hidx,remidx)*self.util(remidx)*lqn.mult(remidx);
                end
            end
            if multcallers > multremote && multremote >0 && ~isinf(multremote)
                %            [multcallers, multremote]
                % we spread the scaling proportionally to the direct
                % caller probabilities
                caller_spreading_ratio = self.ptaskcallers(tidx,callers);
                caller_spreading_ratio = caller_spreading_ratio/sum(caller_spreading_ratio);
                for c=callers
                    ilscaling(c,tidx) = min(ilscaling(c,tidx), multremote / multcallers .* caller_spreading_ratio(find(c==callers)));
                end
            end
        end
    end
end
self.ilscaling = ilscaling;
self.njobs = self.njobsorig .* ilscaling;
end
