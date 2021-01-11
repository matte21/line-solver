function [result, parsed] = getResults(self)
% [RESULT, PARSED] = GETRESULTS()

options = self.getOptions;
switch options.method
    case {'jsim','default'}
        [result, parsed] = self.getResultsJSIM;
    otherwise
        [result, parsed] = self.getResultsJMVA;
end

sn = self.model.getStruct;

for m=1:length(result.metric)
    metric = result.metric{m};
    switch metric.measureType
        case MetricType.QLen
            i = sn.nodeToStation(cellfun(@(c) strcmp(c,metric.station), sn.nodenames));
            r = find(cellfun(@(c) strcmp(c,metric.class), sn.classnames));
            if isinf(sn.njobs(r))
                result.Avg.Q(i,r) = metric.meanValue;
            else % 'closed'
                N = sn.njobs;
                chainIdx = find(cellfun(@any,strfind(sn.classnames,metric.class)));
                if metric.analyzedSamples > sum(sn.njobs(chainIdx))  % for a class to be considered recurrent we ask more samples than jobs in the corresponding closed chain
                    result.Avg.Q(i,r) = metric.meanValue;
                else
                    result.Avg.Q(i,r) = 0;
                end
            end
        case MetricType.Util
            i = sn.nodeToStation(cellfun(@(c) strcmp(c,metric.station), sn.nodenames));
            r = find(cellfun(@(c) strcmp(c,metric.class), sn.classnames));
            if isinf(sn.njobs(r))
                result.Avg.U(i,r) = metric.meanValue;
            else % 'closed'
                N = sn.njobs;
                chainIdx = find(cellfun(@any,strfind(sn.classnames,metric.class)));
                if metric.analyzedSamples > sum(sn.njobs(chainIdx))  % for a class to be considered recurrent we ask more samples than jobs in the corresponding closed chain
                    result.Avg.U(i,r) = metric.meanValue;
                else
                    result.Avg.U(i,r) = 0;
                end
            end
        case MetricType.RespT
            i = sn.nodeToStation(cellfun(@(c) strcmp(c,metric.station), sn.nodenames));
            r = find(cellfun(@(c) strcmp(c,metric.class), sn.classnames));
            if isinf(sn.njobs(r))
                result.Avg.R(i,r) = metric.meanValue;
            else % 'closed'
                N = sn.njobs;
                chainIdx = find(cellfun(@any,strfind(sn.classnames,metric.class)));
                if metric.analyzedSamples > sum(sn.njobs(chainIdx))  % for a class to be considered recurrent we ask more samples than jobs in the corresponding closed chain
                    result.Avg.R(i,r) = metric.meanValue;
                else
                    result.Avg.R(i,r) = 0;
                end
            end
        case MetricType.Tput
            i = sn.nodeToStation(cellfun(@(c) strcmp(c,metric.station), sn.nodenames));
            r = find(cellfun(@(c) strcmp(c,metric.class), sn.classnames));
            if isinf(sn.njobs(r))
                result.Avg.T(i,r) = metric.meanValue;
            else % 'closed'
                N = sn.njobs;
                chainIdx = find(cellfun(@any,strfind(sn.classnames,metric.class)));
                if metric.analyzedSamples > sum(sn.njobs(chainIdx))  % for a class to be considered recurrent we ask more samples than jobs in the corresponding closed chain
                    result.Avg.T(i,r) = metric.meanValue;
                else
                    result.Avg.T(i,r) = 0;
                end
            end
            
    end
self.result = result;    
end
end