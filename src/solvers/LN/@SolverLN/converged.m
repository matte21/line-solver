function bool = converged(self, it)
% BOOL = CONVERGED(IT)
%
% Apply convergence test to the SolverLN iterations. As the solver keeps
% iterating, this method maintains a moving avg of the recent results based
% on which it averages across the layer the maximum queue-length error.
% Convergence is tested by resetting all layers (to avoid caching) and
% doing an extra iteration. If the iteration keeps fulfilling the error
% requirements for convergence, then the solver completes.

bool = false;
iter_min = min(30,ceil(self.options.iter_max/4));
E = self.nlayers;

%% Start moving average to help convergence
% wnd_size = max(5,ceil(iter_min/5)); % moving window size
% mov_avg_weight = 1/wnd_size;
% results = self.results; % faster in matlab
% if it>=iter_min % assume steady-state
%     for e=1:E
%         results{end,e}.QN = mov_avg_weight*results{end,e}.QN;
%         results{end,e}.UN = mov_avg_weight*results{end,e}.UN;
%         results{end,e}.RN = mov_avg_weight*results{end,e}.RN;
%         results{end,e}.TN = mov_avg_weight*results{end,e}.TN;
%         results{end,e}.AN = mov_avg_weight*results{end,e}.AN;
%         results{end,e}.WN = mov_avg_weight*results{end,e}.WN;
%         for k=1:(wnd_size-1)
%             results{end,e}.QN = results{end,e}.QN + results{end-k,e}.QN * mov_avg_weight;
%             results{end,e}.UN = results{end,e}.UN + results{end-k,e}.UN * mov_avg_weight;
%             results{end,e}.RN = results{end,e}.RN + results{end-k,e}.RN * mov_avg_weight;
%             results{end,e}.TN = results{end,e}.TN + results{end-k,e}.TN * mov_avg_weight;
%             results{end,e}.AN = results{end,e}.AN + results{end-k,e}.AN * mov_avg_weight;
%             results{end,e}.WN = results{end,e}.WN + results{end-k,e}.WN * mov_avg_weight;
%         end
%     end
% end

results = self.results; % faster in matlab
% Cesaro summation
if ~isempty(self.averagingstart)
    wnd_size = (it-self.averagingstart+1); % window size
    mov_avg_weight = 1/wnd_size;
    if it>=iter_min % assume steady-state
        for e=1:E
            results{end,e}.QN = mov_avg_weight*results{end,e}.QN;
            results{end,e}.UN = mov_avg_weight*results{end,e}.UN;
            results{end,e}.RN = mov_avg_weight*results{end,e}.RN;
            results{end,e}.TN = mov_avg_weight*results{end,e}.TN;
            results{end,e}.AN = mov_avg_weight*results{end,e}.AN;
            results{end,e}.WN = mov_avg_weight*results{end,e}.WN;
            for k=1:(wnd_size-1)
                results{end,e}.QN = results{end,e}.QN + results{end-k,e}.QN * mov_avg_weight;
                results{end,e}.UN = results{end,e}.UN + results{end-k,e}.UN * mov_avg_weight;
                results{end,e}.RN = results{end,e}.RN + results{end-k,e}.RN * mov_avg_weight;
                results{end,e}.TN = results{end,e}.TN + results{end-k,e}.TN * mov_avg_weight;
                results{end,e}.AN = results{end,e}.AN + results{end-k,e}.AN * mov_avg_weight;
                results{end,e}.WN = results{end,e}.WN + results{end-k,e}.WN * mov_avg_weight;
            end
        end
    end
end
self.results = results;

%% Take as error metric the max qlen-error averaged across layers
if it>1
    self.maxitererr(it) = 0;
    for e = 1:E
        metric = results{end,e}.QN;
        metric_1 = results{end-1,e}.QN;
        N = sum(self.ensemble{e}.getNumberOfJobs);
        if N>0
            try
                IterErr = nanmax(abs(metric(:) - metric_1(:)))/N;
            catch
                IterErr = 0;
            end
            self.maxitererr(it) = self.maxitererr(it) + IterErr;
        end
    end
    if self.options.verbose
        line_printf(sprintf('\bChange: %f.',self.maxitererr(it)/E));
        if it==iter_min
            if self.options.verbose
                line_printf( ' Starting averaging to help convergence.');
                self.averagingstart = it;
            end
        end
    end
end

%% Check convergence. Do not allow to converge in less than 2 iterations.
if it>2 && self.maxitererr(it) < self.options.iter_tol && self.maxitererr(it-1) < self.options.iter_tol&& self.maxitererr(it-1) < self.options.iter_tol
    if ~self.hasconverged % if potential convergence has just been detected
        % do a hard reset of every layer to check that this is really the fixed point
        for e=1:E
            self.ensemble{e}.reset();
        end
        if self.options.verbose
            line_printf(sprintf('\b Testing convergence.')); %Deep reset.');
        end
        self.hasconverged = true; % if it passes the change again next time then complete
    else
        if self.options.verbose
            line_printf(sprintf('\nSolverLN completed in %d iterations.',size(results,1)));
        end
        bool = true;
    end
else
    self.hasconverged = false;
end
end