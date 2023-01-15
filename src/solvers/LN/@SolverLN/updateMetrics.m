function updateMetrics(self, it)
switch self.getOptions.method
    case 'default'
        updateMetricsDefault(self,it)
    case 'moment3'
        % this method propagates through the layers 3 moments of the
        % response time distribution computed from the CDF obtained by the
        % solvers of the individual layers. In the present implementation,
        % calls are still assumed to be exponentially distributed.
        updateMetricsMomentBased(self,it)
end
end