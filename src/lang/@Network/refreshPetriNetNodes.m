function nvars = refreshPetriNetNodes(self)
% NVARS = REFRESHPETRINETNODES()

nvars = zeros(self.getNumberOfNodes, 1); 

for ind=1:self.getNumberOfNodes
    node = self.getNodeByIndex(ind);
    switch class(node)
        case 'Place'
            % noop
        case 'Transition'
            self.qn.nmodes(ind) = length(node.modeNames);
            self.qn.modenames{ind,1} = node.modeNames;
            self.qn.enabling{ind,1} = node.enablingConditions;
            self.qn.inhibiting{ind,1} = node.inhibitingConditions;
            self.qn.firing{ind,1} = node.firingOutcomes;
            self.qn.nmodeservers{ind,1} = node.numbersOfServers;
            self.qn.fireprio{ind,1} = node.firingPriorities;
            self.qn.fireweight{ind,1} = node.firingWeights;
            self.qn.firingid{ind,1} = node.timingStrategies;
            for m = 1:self.qn.nmodes(ind)
                self.qn.firingproc{ind,1}{m} = node.distributions{m}.getRepresentation;
                self.qn.firingprocid{ind,1}(m) = ProcessType.toId(ProcessType.fromText(class(node.distributions{m})));
                self.qn.firingphases{ind,1}(m) = node.distributions{m}.getNumberOfPhases;
            end
    end
end
end