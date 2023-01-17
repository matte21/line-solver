function [simDoc, section] = saveTimingStrategies(self, simDoc, section, ind)
% [SIMDOC, SECTION] = SAVETIMINGSTRATEGIES(SIMDOC, SECTION, NODEIDX)

% Copyright (c) 2012-2023, Imperial College London
% All rights reserved.

strategyNode = simDoc.createElement('parameter');
strategyNode.setAttribute('array', 'true');
strategyNode.setAttribute('classPath', 'jmt.engine.NetStrategies.ServiceStrategy');
strategyNode.setAttribute('name', 'timingStrategies');

sn = self.getStruct;
numOfModes = sn.nodeparam{ind}.nmodes;
for m=1:numOfModes
    
    timimgStrategyNode = simDoc.createElement('subParameter');
    
    if sn.nodeparam{ind}.firingid(m) == TimingStrategy.ID_IMMEDIATE
        timimgStrategyNode.setAttribute('classPath', 'jmt.engine.NetStrategies.ServiceStrategies.ZeroServiceTimeStrategy');
        timimgStrategyNode.setAttribute('name', 'ZeroServiceTimeStrategy');
    elseif sn.nodeparam{ind}.firingprocid(m) == ProcessType.ID_APH|| sn.nodeparam{ind}.firingprocid(m) == ProcessType.ID_COXIAN || (sn.nodeparam{ind}.firingphases(m)>2 && sn.nodeparam{ind}.firingprocid(m) == ProcessType.ID_HYPEREXP) %|| (sn.phases(i,r)>2 && sn.procid(i,r) == ProcessType.ID_COXIAN) || (sn.phases(i,r)>2 && sn.procid(i,r) == ProcessType.ID_HYPEREXP)
        % Coxian and HyperExp have 2 parameters when they have a {mu, p} input specification
        timimgStrategyNode.setAttribute('classPath', 'jmt.engine.NetStrategies.ServiceStrategies.ServiceTimeStrategy');
        timimgStrategyNode.setAttribute('name', 'timingStrategy');
        distributionNode = simDoc.createElement('subParameter');
        distributionNode.setAttribute('classPath', 'jmt.engine.random.PhaseTypeDistr');
        distributionNode.setAttribute('name', 'Phase-Type');
        distrParNode = simDoc.createElement('subParameter');
        distrParNode.setAttribute('classPath', 'jmt.engine.random.PhaseTypePar');
        distrParNode.setAttribute('name', 'distrPar');
        
        subParNodeAlpha = simDoc.createElement('subParameter');
        subParNodeAlpha.setAttribute('array', 'true');
        subParNodeAlpha.setAttribute('classPath', 'java.lang.Object');
        subParNodeAlpha.setAttribute('name', 'alpha');
        subParNodeAlphaVec = simDoc.createElement('subParameter');
        subParNodeAlphaVec.setAttribute('array', 'true');
        subParNodeAlphaVec.setAttribute('classPath', 'java.lang.Object');
        subParNodeAlphaVec.setAttribute('name', 'vector');
        PH=sn.nodeparam{ind}.firingproc{m};
        alpha = abs(map_pie(PH));
        nphases=sn.nodeparam{ind}.firingphases(m);
        for k=1:nphases
            subParNodeAlphaElem = simDoc.createElement('subParameter');
            subParNodeAlphaElem.setAttribute('classPath', 'java.lang.Double');
            subParNodeAlphaElem.setAttribute('name', 'entry');
            subParValue = simDoc.createElement('value');
            subParValue.appendChild(simDoc.createTextNode(sprintf('%.12f',alpha(k))));
            subParNodeAlphaElem.appendChild(subParValue);
            subParNodeAlphaVec.appendChild(subParNodeAlphaElem);
        end
        
        subParNodeT = simDoc.createElement('subParameter');
        subParNodeT.setAttribute('array', 'true');
        subParNodeT.setAttribute('classPath', 'java.lang.Object');
        subParNodeT.setAttribute('name', 'T');
        T = PH{1};
        for k=1:nphases
            subParNodeTvec = simDoc.createElement('subParameter');
            subParNodeTvec.setAttribute('array', 'true');
            subParNodeTvec.setAttribute('classPath', 'java.lang.Object');
            subParNodeTvec.setAttribute('name', 'vector');
            for j=1:nphases
                subParNodeTElem = simDoc.createElement('subParameter');
                subParNodeTElem.setAttribute('classPath', 'java.lang.Double');
                subParNodeTElem.setAttribute('name', 'entry');
                subParValue = simDoc.createElement('value');
                if k==j
                    subParValue.appendChild(simDoc.createTextNode(sprintf('%.12f',-abs(T(k,j)))));
                else
                    subParValue.appendChild(simDoc.createTextNode(sprintf('%.12f',abs(T(k,j)))));
                end
                subParNodeTElem.appendChild(subParValue);
                subParNodeTvec.appendChild(subParNodeTElem);
            end
            subParNodeT.appendChild(subParNodeTvec);
        end
        
        subParNodeAlpha.appendChild(subParNodeAlphaVec);
        distrParNode.appendChild(subParNodeAlpha);
        distrParNode.appendChild(subParNodeT);
        timimgStrategyNode.appendChild(distributionNode);
        timimgStrategyNode.appendChild(distrParNode);
    elseif sn.nodeparam{ind}.firingprocid(m) == ProcessType.ID_MAP
        timimgStrategyNode.setAttribute('classPath', 'jmt.engine.NetStrategies.ServiceStrategies.ServiceTimeStrategy');
        timimgStrategyNode.setAttribute('name', 'timingStrategy');
        distributionNode = simDoc.createElement('subParameter');
        distributionNode.setAttribute('classPath', 'jmt.engine.random.MAPDistr');
        distributionNode.setAttribute('name', 'Burst (MAP)');
        distrParNode = simDoc.createElement('subParameter');
        distrParNode.setAttribute('classPath', 'jmt.engine.random.MAPPar');
        distrParNode.setAttribute('name', 'distrPar');
        
        MAP = sn.nodeparam{ind}.firingproc{m};
        
        subParNodeD0 = simDoc.createElement('subParameter');
        subParNodeD0.setAttribute('array', 'true');
        subParNodeD0.setAttribute('classPath', 'java.lang.Object');
        subParNodeD0.setAttribute('name', 'D0');
        
        D0 = MAP{1};
        for k=1:nphases
            subParNodeD0vec = simDoc.createElement('subParameter');
            subParNodeD0vec.setAttribute('array', 'true');
            subParNodeD0vec.setAttribute('classPath', 'java.lang.Object');
            subParNodeD0vec.setAttribute('name', 'vector');
            for j=1:nphases
                subParNodeD0Elem = simDoc.createElement('subParameter');
                subParNodeD0Elem.setAttribute('classPath', 'java.lang.Double');
                subParNodeD0Elem.setAttribute('name', 'entry');
                subParValue = simDoc.createElement('value');
                subParValue.appendChild(simDoc.createTextNode(sprintf('%.12f',D0(k,j))));
                subParNodeD0Elem.appendChild(subParValue);
                subParNodeD0vec.appendChild(subParNodeD0Elem);
            end
            subParNodeD0.appendChild(subParNodeD0vec);
        end
        distrParNode.appendChild(subParNodeD0);
        
        subParNodeD1 = simDoc.createElement('subParameter');
        subParNodeD1.setAttribute('array', 'true');
        subParNodeD1.setAttribute('classPath', 'java.lang.Object');
        subParNodeD1.setAttribute('name', 'D1');
        D1 = MAP{2};
        for k=1:nphases
            subParNodeD1vec = simDoc.createElement('subParameter');
            subParNodeD1vec.setAttribute('array', 'true');
            subParNodeD1vec.setAttribute('classPath', 'java.lang.Object');
            subParNodeD1vec.setAttribute('name', 'vector');
            for j=1:nphases
                subParNodeD1Elem = simDoc.createElement('subParameter');
                subParNodeD1Elem.setAttribute('classPath', 'java.lang.Double');
                subParNodeD1Elem.setAttribute('name', 'entry');
                subParValue = simDoc.createElement('value');
                subParValue.appendChild(simDoc.createTextNode(sprintf('%.12f',D1(k,j))));
                subParNodeD1Elem.appendChild(subParValue);
                subParNodeD1vec.appendChild(subParNodeD1Elem);
            end
            subParNodeD1.appendChild(subParNodeD1vec);
        end
        distrParNode.appendChild(subParNodeD1);
        timimgStrategyNode.appendChild(distributionNode);
        timimgStrategyNode.appendChild(distrParNode);
    else
        timimgStrategyNode.setAttribute('classPath', 'jmt.engine.NetStrategies.ServiceStrategies.ServiceTimeStrategy');
        timimgStrategyNode.setAttribute('name', 'timingStrategy');
        
        distributionNode = simDoc.createElement('subParameter');
        switch sn.nodeparam{ind}.firingprocid(m)
            case ProcessType.ID_DET
                javaClass = 'jmt.engine.random.DeterministicDistr';
                javaParClass = 'jmt.engine.random.DeterministicDistrPar';
            case ProcessType.ID_COXIAN
                javaClass = 'jmt.engine.random.CoxianDistr';
                javaParClass = 'jmt.engine.random.CoxianPar';
            case ProcessType.ID_ERLANG
                javaClass = 'jmt.engine.random.Erlang';
                javaParClass = 'jmt.engine.random.ErlangPar';
            case ProcessType.ID_EXP
                javaClass = 'jmt.engine.random.Exponential';
                javaParClass = 'jmt.engine.random.ExponentialPar';
            case ProcessType.ID_GAMMA
                javaClass = 'jmt.engine.random.GammaDistr';
                javaParClass = 'jmt.engine.random.GammaDistrPar';
            case ProcessType.ID_HYPEREXP
                javaClass = 'jmt.engine.random.HyperExp';
                javaParClass = 'jmt.engine.random.HyperExpPar';
            case ProcessType.ID_PARETO
                javaClass = 'jmt.engine.random.Pareto';
                javaParClass = 'jmt.engine.random.ParetoPar';
            case ProcessType.ID_WEIBULL
                javaClass = 'jmt.engine.random.Weibull';
                javaParClass = 'jmt.engine.random.WeibullPar';
            case ProcessType.ID_LOGNORMAL
                javaClass = 'jmt.engine.random.Lognormal';
                javaParClass = 'jmt.engine.random.LognormalPar';
            case ProcessType.ID_UNIFORM
                javaClass = 'jmt.engine.random.Uniform';
                javaParClass = 'jmt.engine.random.UniformPar';
            case ProcessType.ID_MMPP2
                javaClass = 'jmt.engine.random.MMPP2Distr';
                javaParClass = 'jmt.engine.random.MMPP2Par';
            case {ProcessType.ID_REPLAYER, ProcessType.ID_TRACE}
                javaClass = 'jmt.engine.random.Replayer';
                javaParClass = 'jmt.engine.random.ReplayerPar';
        end
        distributionNode.setAttribute('classPath', javaClass);
        switch sn.nodeparam{ind}.firingprocid(m)
            case {ProcessType.ID_REPLAYER, ProcessType.ID_TRACE}
                distributionNode.setAttribute('name', 'Replayer');
            case ProcessType.ID_EXP
                distributionNode.setAttribute('name', 'Exponential');
            case ProcessType.ID_HYPEREXP
                distributionNode.setAttribute('name', 'Hyperexponential');
            otherwise
                distributionNode.setAttribute('name', ProcessType.toText(ProcessType.fromId(sn.nodeparam{ind}.firingprocid(m))));
        end
        timimgStrategyNode.appendChild(distributionNode);
        
        distrParNode = simDoc.createElement('subParameter');
        distrParNode.setAttribute('classPath', javaParClass);
        distrParNode.setAttribute('name', 'distrPar');
        
        switch sn.nodeparam{ind}.firingprocid(m)
            case ProcessType.ID_DET
                subParNodeAlpha = simDoc.createElement('subParameter');
                subParNodeAlpha.setAttribute('classPath', 'java.lang.Double');
                subParNodeAlpha.setAttribute('name', 't');
                subParValue = simDoc.createElement('value');
                subParValue.appendChild(simDoc.createTextNode(sprintf('%.12f',map_lambda(sn.nodeparam{ind}.firingproc{m}))));
                subParNodeAlpha.appendChild(subParValue);
                distrParNode.appendChild(subParNodeAlpha);
            case ProcessType.ID_EXP
                subParNodeAlpha = simDoc.createElement('subParameter');
                subParNodeAlpha.setAttribute('classPath', 'java.lang.Double');
                subParNodeAlpha.setAttribute('name', 'lambda');
                subParValue = simDoc.createElement('value');
                subParValue.appendChild(simDoc.createTextNode(sprintf('%.12f',map_lambda(sn.nodeparam{ind}.firingproc{m}))));
                subParNodeAlpha.appendChild(subParValue);
                distrParNode.appendChild(subParNodeAlpha);
            case ProcessType.ID_HYPEREXP
                subParNodeAlpha = simDoc.createElement('subParameter');
                subParNodeAlpha.setAttribute('classPath', 'java.lang.Double');
                subParNodeAlpha.setAttribute('name', 'p');
                subParValue = simDoc.createElement('value');
                pie = map_pie(sn.nodeparam{ind}.firingprocid(m));
                subParValue.appendChild(simDoc.createTextNode(sprintf('%.12f',pie(1))));
                subParNodeAlpha.appendChild(subParValue);
                distrParNode.appendChild(subParNodeAlpha);
                subParNodeAlpha = simDoc.createElement('subParameter');
                subParNodeAlpha.setAttribute('classPath', 'java.lang.Double');
                subParNodeAlpha.setAttribute('name', 'lambda1');
                subParValue = simDoc.createElement('value');
                subParValue.appendChild(simDoc.createTextNode(sprintf('%.12f',-sn.nodeparam{ind}.firingproc{m}{1}(1,1))));
                subParNodeAlpha.appendChild(subParValue);
                distrParNode.appendChild(subParNodeAlpha);
                subParNodeAlpha = simDoc.createElement('subParameter');
                subParNodeAlpha.setAttribute('classPath', 'java.lang.Double');
                subParNodeAlpha.setAttribute('name', 'lambda2');
                subParValue = simDoc.createElement('value');
                subParValue.appendChild(simDoc.createTextNode(sprintf('%.12f',-sn.nodeparam{ind}.firingproc{m}{1}(2,2))));
                subParNodeAlpha.appendChild(subParValue);
                distrParNode.appendChild(subParNodeAlpha);
            case ProcessType.ID_ERLANG
                subParNodeAlpha = simDoc.createElement('subParameter');
                subParNodeAlpha.setAttribute('classPath', 'java.lang.Double');
                subParNodeAlpha.setAttribute('name', 'alpha');
                subParValue = simDoc.createElement('value');
                timingrate = map_lambda(sn.nodeparam{ind}.firingproc{m});
                nphases = sn.nodeparam{ind}.firingphases(m);
                subParValue.appendChild(simDoc.createTextNode(sprintf('%.12f',timingrate*nphases)));
                subParNodeAlpha.appendChild(subParValue);
                distrParNode.appendChild(subParNodeAlpha);
                subParNodeAlpha = simDoc.createElement('subParameter');
                subParNodeAlpha.setAttribute('classPath', 'java.lang.Long');
                subParNodeAlpha.setAttribute('name', 'r');
                subParValue = simDoc.createElement('value');
                subParValue.appendChild(simDoc.createTextNode(sprintf('%d',nphases)));
                subParNodeAlpha.appendChild(subParValue);
                distrParNode.appendChild(subParNodeAlpha);
            case ProcessType.ID_MMPP2
                subParNodeAlpha = simDoc.createElement('subParameter');
                subParNodeAlpha.setAttribute('classPath', 'java.lang.Double');
                subParNodeAlpha.setAttribute('name', 'lambda0');
                subParValue = simDoc.createElement('value');
                subParValue.appendChild(simDoc.createTextNode(sprintf('%.12f',sn.nodeparam{ind}.firingproc{m}{2}(1,1))));
                subParNodeAlpha.appendChild(subParValue);
                distrParNode.appendChild(subParNodeAlpha);
                subParNodeAlpha = simDoc.createElement('subParameter');
                subParNodeAlpha.setAttribute('classPath', 'java.lang.Double');
                subParNodeAlpha.setAttribute('name', 'lambda1');
                subParValue = simDoc.createElement('value');
                subParValue.appendChild(simDoc.createTextNode(sprintf('%.12f',sn.nodeparam{ind}.firingproc{m}{2}(2,2))));
                subParNodeAlpha.appendChild(subParValue);
                distrParNode.appendChild(subParNodeAlpha);
                subParNodeAlpha = simDoc.createElement('subParameter');
                subParNodeAlpha.setAttribute('classPath', 'java.lang.Double');
                subParNodeAlpha.setAttribute('name', 'sigma0');
                subParValue = simDoc.createElement('value');
                subParValue.appendChild(simDoc.createTextNode(sprintf('%.12f',sn.nodeparam{ind}.firingproc{m}{1}(1,2))));
                subParNodeAlpha.appendChild(subParValue);
                distrParNode.appendChild(subParNodeAlpha);
                subParNodeAlpha = simDoc.createElement('subParameter');
                subParNodeAlpha.setAttribute('classPath', 'java.lang.Double');
                subParNodeAlpha.setAttribute('name', 'sigma1');
                subParValue = simDoc.createElement('value');
                subParValue.appendChild(simDoc.createTextNode(sprintf('%.12f',sn.nodeparam{ind}.firingproc{m}{1}(2,1))));
                subParNodeAlpha.appendChild(subParValue);
                distrParNode.appendChild(subParNodeAlpha);
            case ProcessType.ID_GAMMA
                line_error(mfilename,sprintf('Unsupported firing distribution for mode %d',m));
                % subParNodeAlpha = simDoc.createElement('subParameter');
                % subParNodeAlpha.setAttribute('classPath', 'java.lang.Double');
                % subParNodeAlpha.setAttribute('name', 'alpha');
                % subParValue = simDoc.createElement('value');
                % subParValue.appendChild(simDoc.createTextNode(sprintf('%.12f',1/sn.scv(i,r))));
                % subParNodeAlpha.appendChild(subParValue);
                % distrParNode.appendChild(subParNodeAlpha);
                % subParNodeAlpha = simDoc.createElement('subParameter');
                % subParNodeAlpha.setAttribute('classPath', 'java.lang.Double');
                % subParNodeAlpha.setAttribute('name', 'beta');
                % subParValue = simDoc.createElement('value');
                % subParValue.appendChild(simDoc.createTextNode(sprintf('%.12f',sn.scv(i,r)/sn.rates(i,r))));
                % subParNodeAlpha.appendChild(subParValue);
                % distrParNode.appendChild(subParNodeAlpha);
            case ProcessType.ID_PARETO
                line_error(mfilename,sprintf('Unsupported firing distribution for mode %d',m));
            case ProcessType.ID_WEIBULL
                line_error(mfilename,sprintf('Unsupported firing distribution for mode %d',m));
            case ProcessType.ID_LOGNORMAL
                line_error(mfilename,sprintf('Unsupported firing distribution for mode %d',m));
                % shape = sqrt(1+1/sn.scv(i,r))+1;
                % scale = 1/sn.rates(i,r) *  (shape - 1) / shape;
                % subParNodeAlpha = simDoc.createElement('subParameter');
                % subParNodeAlpha.setAttribute('classPath', 'java.lang.Double');
                % subParNodeAlpha.setAttribute('name', 'alpha'); % shape
                % subParValue = simDoc.createElement('value');
                % subParValue.appendChild(simDoc.createTextNode(sprintf('%.12f',shape)));
                % subParNodeAlpha.appendChild(subParValue);
                % distrParNode.appendChild(subParNodeAlpha);
                % subParNodeAlpha = simDoc.createElement('subParameter');
                % subParNodeAlpha.setAttribute('classPath', 'java.lang.Double');
                % subParNodeAlpha.setAttribute('name', 'k'); % scale
                % subParValue = simDoc.createElement('value');
                % subParValue.appendChild(simDoc.createTextNode(sprintf('%.12f',scale)));
                % subParNodeAlpha.appendChild(subParValue);
                % distrParNode.appendChild(subParNodeAlpha);
            case ProcessType.ID_UNIFORM
                line_error(mfilename,sprintf('Unsupported firing distribution for mode %d',m));
                % maxVal = ((sqrt(12*sn.scv(i,r)/sn.rates(i,r)^2))+2/sn.rates(i,r))/2;
                % minVal = 2/sn.rates(i,r)-maxVal;
                % subParNodeAlpha = simDoc.createElement('subParameter');
                % subParNodeAlpha.setAttribute('classPath', 'java.lang.Double');
                % subParNodeAlpha.setAttribute('name', 'min'); % shape
                % subParValue = simDoc.createElement('value');
                % subParValue.appendChild(simDoc.createTextNode(sprintf('%.12f',minVal)));
                % subParNodeAlpha.appendChild(subParValue);
                % distrParNode.appendChild(subParNodeAlpha);
                % subParNodeAlpha = simDoc.createElement('subParameter');
                % subParNodeAlpha.setAttribute('classPath', 'java.lang.Double');
                % subParNodeAlpha.setAttribute('name', 'max'); % scale
                % subParValue = simDoc.createElement('value');
                % subParValue.appendChild(simDoc.createTextNode(sprintf('%.12f',maxVal)));
                % subParNodeAlpha.appendChild(subParValue);
                % distrParNode.appendChild(subParNodeAlpha);
            case {ProcessType.ID_REPLAYER, ProcessType.ID_TRACE}
                line_error(mfilename,sprintf('Unsupported firing distribution for mode %d',m));
                % subParNodeAlpha = simDoc.createElement('subParameter');
                % subParNodeAlpha.setAttribute('classPath', 'java.lang.String');
                % subParNodeAlpha.setAttribute('name', 'fileName');
                % subParValue = simDoc.createElement('value');
                % subParValue.appendChild(simDoc.createTextNode(sn.nodeparam{ind}{r}.fileName));
                % subParNodeAlpha.appendChild(subParValue);
                % distrParNode.appendChild(subParNodeAlpha);
        end
        timimgStrategyNode.appendChild(distrParNode);
    end
    strategyNode.appendChild(timimgStrategyNode);
end
section.appendChild(strategyNode);
end


