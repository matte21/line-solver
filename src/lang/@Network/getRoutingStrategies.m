function rtTypes = getRoutingStrategies(self)
% RTTYPES = GETROUTINGSTRATEGIES()

rtTypes = zeros(self.getNumberOfNodes,self.getNumberOfClasses);
for ind=1:self.getNumberOfNodes
    for r=1:self.getNumberOfClasses
        switch self.nodes{ind}.output.outputStrategy{r}{2}
            case RoutingStrategy.RAND
                rtTypes(ind,r) = RoutingStrategy.ID_RAND;
            case RoutingStrategy.PROB
                rtTypes(ind,r) = RoutingStrategy.ID_PROB;
            case RoutingStrategy.RRB
                rtTypes(ind,r) = RoutingStrategy.ID_RRB;
            case RoutingStrategy.JSQ
                rtTypes(ind,r) = RoutingStrategy.ID_JSQ;
            case RoutingStrategy.DISABLED
                rtTypes(ind,r) = RoutingStrategy.ID_DISABLED;
        end
    end
end
end