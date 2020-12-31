function [simDoc, section] = saveJoinStrategy(self, simDoc, section, ind)
% [SIMDOC, SECTION] = SAVEJOINSTRATEGY(SIMDOC, SECTION, NODEIDX)

% Copyright (c) 2012-2021, Imperial College London
% All rights reserved.
strategyNode = simDoc.createElement('parameter');
strategyNode.setAttribute('array', 'true');
strategyNode.setAttribute('classPath', 'jmt.engine.NetStrategies.JoinStrategy');
strategyNode.setAttribute('name', 'JoinStrategy');

qn = self.getStruct;
numOfClasses = qn.nclasses;
for r=1:numOfClasses    
    switch qn.varsparam{ind}.joinStrategy{r}
        case JoinStrategy.STD
            refClassNode2 = simDoc.createElement('refClass');
            refClassNode2.appendChild(simDoc.createTextNode(qn.classnames{r}));
            strategyNode.appendChild(refClassNode2);
            
            joinStrategyNode = simDoc.createElement('subParameter');
            joinStrategyNode.setAttribute('classPath', 'jmt.engine.NetStrategies.JoinStrategies.NormalJoin');
            joinStrategyNode.setAttribute('name', 'Standard Join');
            reqNode = simDoc.createElement('subParameter');
            reqNode.setAttribute('classPath', 'java.lang.Integer');
            reqNode.setAttribute('name', 'numRequired');
            valueNode = simDoc.createElement('value');
            valueNode.appendChild(simDoc.createTextNode(int2str(qn.varsparam{ind}.joinRequired{r})));
            reqNode.appendChild(valueNode);
            joinStrategyNode.appendChild(reqNode);
            strategyNode.appendChild(joinStrategyNode);
            section.appendChild(strategyNode);
        case JoinStrategy.Quorum
            refClassNode2 = simDoc.createElement('refClass');
            refClassNode2.appendChild(simDoc.createTextNode(qn.classnames{r}));
            strategyNode.appendChild(refClassNode2);
            
            joinStrategyNode = simDoc.createElement('subParameter');
            joinStrategyNode.setAttribute('classPath', 'jmt.engine.NetStrategies.JoinStrategies.PartialJoin');
            joinStrategyNode.setAttribute('name', 'Quorum');
            reqNode = simDoc.createElement('subParameter');
            reqNode.setAttribute('classPath', 'java.lang.Integer');
            reqNode.setAttribute('name', 'numRequired');
            valueNode = simDoc.createElement('value');
            valueNode.appendChild(simDoc.createTextNode(int2str(qn.varsparam{ind}.joinRequired{r})));
            reqNode.appendChild(valueNode);
            joinStrategyNode.appendChild(reqNode);
            strategyNode.appendChild(joinStrategyNode);
            section.appendChild(strategyNode);
        case JoinStrategy.Guard
            refClassNode2 = simDoc.createElement('refClass');
            refClassNode2.appendChild(simDoc.createTextNode(qn.classnames{r}));
            strategyNode.appendChild(refClassNode2);
            
            joinStrategyNode = simDoc.createElement('subParameter');
            joinStrategyNode.setAttribute('classPath', 'jmt.engine.NetStrategies.JoinStrategies.PartialJoin');
            joinStrategyNode.setAttribute('name', 'Quorum');
            reqNode = simDoc.createElement('subParameter');
            reqNode.setAttribute('classPath', 'java.lang.Integer');
            reqNode.setAttribute('name', 'numRequired');
            valueNode = simDoc.createElement('value');
            valueNode.appendChild(simDoc.createTextNode(int2str(qn.varsparam{ind}.joinRequired{r})));
            reqNode.appendChild(valueNode);
            joinStrategyNode.appendChild(reqNode);
            strategyNode.appendChild(joinStrategyNode);
            section.appendChild(strategyNode);
    end
end
end
