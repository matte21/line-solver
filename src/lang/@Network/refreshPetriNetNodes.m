function refreshPetriNetNodes(self)
% REFRESHPETRINETNODES()

for ind=1:self.getNumberOfNodes
    node = self.getNodeByIndex(ind);
    switch class(node)
        case 'Place'
            % noop
        case 'Transition'
            self.sn.nmodes(ind) = length(node.modeNames);
            self.sn.modenames{ind,1} = node.modeNames;
            self.sn.enabling{ind,1} = {};
            self.sn.inhibiting{ind,1} = {};
            self.sn.firing{ind,1} = {};
            for m = 1:self.sn.nmodes(ind)
                self.sn.enabling{ind,1}{m} = node.enablingConditions{m};
                self.sn.inhibiting{ind,1}{m} = node.inhibitingConditions{m};
                self.sn.firing{ind,1}{m} = node.firingOutcomes{m};
            end
            self.sn.nmodeservers{ind,1} = node.numbersOfServers;
            self.sn.fireprio{ind,1} = node.firingPriorities;
            self.sn.fireweight{ind,1} = node.firingWeights;
            self.sn.firingid{ind,1} = node.timingStrategies;
            for m = 1:self.sn.nmodes(ind)
                self.sn.firingproc{ind,1}{m} = node.distributions{m}.getRepres;
                self.sn.firingprocid{ind,1}(m) = ProcessType.toId(ProcessType.fromText(class(node.distributions{m})));
                self.sn.firingphases{ind,1}(m) = node.distributions{m}.getNumberOfPhases;
            end
    end
end
end