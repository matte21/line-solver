function [simDoc, section] = saveRoutingStrategy(self, simDoc, section, ind)
% [SIMDOC, SECTION] = SAVEROUTINGSTRATEGY(SIMDOC, SECTION, NODEIDX)

% Copyright (c) 2012-2021, Imperial College London
% All rights reserved.
strategyNode = simDoc.createElement('parameter');
strategyNode.setAttribute('array', 'true');
strategyNode.setAttribute('classPath', 'jmt.engine.NetStrategies.RoutingStrategy');
strategyNode.setAttribute('name', 'RoutingStrategy');

qn = self.getStruct;
M = qn.nnodes;
K = qn.nclasses;
i = ind;
% since the class switch node always outputs to a single node, it is faster
% to translate it to RAND. Also some problems with qn.rt value otherwise.
if qn.nodetype(i) == NodeType.ClassSwitch
    qn.routing(i,:) = RoutingStrategy.ID_RAND;
end
for r=1:K
    refClassNode = simDoc.createElement('refClass');
    refClassNode.appendChild(simDoc.createTextNode(qn.classnames{r}));
    strategyNode.appendChild(refClassNode);
    switch qn.routing(i,r)
        case RoutingStrategy.ID_RAND
            concStratNode = simDoc.createElement('subParameter');
            concStratNode.setAttribute('classPath', 'jmt.engine.NetStrategies.RoutingStrategies.RandomStrategy');
            concStratNode.setAttribute('name', 'Random');
        case RoutingStrategy.ID_RRB
            concStratNode = simDoc.createElement('subParameter');
            concStratNode.setAttribute('classPath', 'jmt.engine.NetStrategies.RoutingStrategies.RoundRobinStrategy');
            concStratNode.setAttribute('name', 'Round Robin');
        case RoutingStrategy.ID_JSQ
            concStratNode = simDoc.createElement('subParameter');
            concStratNode.setAttribute('classPath', 'jmt.engine.NetStrategies.RoutingStrategies.ShortestQueueLengthRoutingStrategy');
            concStratNode.setAttribute('name', 'Join the Shortest Queue (JSQ)');
        case RoutingStrategy.ID_PROB
            concStratNode = simDoc.createElement('subParameter');
            concStratNode.setAttribute('classPath', 'jmt.engine.NetStrategies.RoutingStrategies.EmpiricalStrategy');
            concStratNode.setAttribute('name', RoutingStrategy.PROB);
            concStratNode2 = simDoc.createElement('subParameter');
            concStratNode2.setAttribute('array', 'true');
            concStratNode2.setAttribute('classPath', 'jmt.engine.random.EmpiricalEntry');
            concStratNode2.setAttribute('name', 'EmpiricalEntryArray');
            for j=find(qn.connmatrix(i,:)) % linked stations
                probRouting = qn.rtnodes((i-1)*K+r,(j-1)*K+r);
                if probRouting > 0
                    concStratNode3 = simDoc.createElement('subParameter');
                    concStratNode3.setAttribute('classPath', 'jmt.engine.random.EmpiricalEntry');
                    concStratNode3.setAttribute('name', 'EmpiricalEntry');
                    concStratNode4Station = simDoc.createElement('subParameter');
                    concStratNode4Station.setAttribute('classPath', 'java.lang.String');
                    concStratNode4Station.setAttribute('name', 'stationName');
                    concStratNode4StationValueNode = simDoc.createElement('value');
                    concStratNode4StationValueNode.appendChild(simDoc.createTextNode(sprintf('%s',qn.nodenames{j})));
                    concStratNode4Station.appendChild(concStratNode4StationValueNode);
                    concStratNode3.appendChild(concStratNode4Station);
                    concStratNode4Probability = simDoc.createElement('subParameter');
                    concStratNode4Probability.setAttribute('classPath', 'java.lang.Double');
                    concStratNode4Probability.setAttribute('name', 'probability');
                    concStratNode4ProbabilityValueNode = simDoc.createElement('value');
                    concStratNode4ProbabilityValueNode.appendChild(simDoc.createTextNode(sprintf('%12.12f',probRouting)));
                    concStratNode4Probability.appendChild(concStratNode4ProbabilityValueNode);                    
                    concStratNode3.appendChild(concStratNode4Station);
                    concStratNode3.appendChild(concStratNode4Probability);
                    concStratNode2.appendChild(concStratNode3);
                end
            end
            concStratNode.appendChild(concStratNode2);
        otherwise
            concStratNode = simDoc.createElement('subParameter');
            concStratNode.setAttribute('classPath', 'jmt.engine.NetStrategies.RoutingStrategies.DisabledRoutingStrategy');
            concStratNode.setAttribute('name', 'Random');
    end
    strategyNode.appendChild(concStratNode);
    section.appendChild(strategyNode);
end
end
