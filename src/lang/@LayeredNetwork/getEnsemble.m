function ensemble = getEnsemble(self)
% ENSEMBLE = GETENSEMBLE()
SolverLN(self).buildLayers;
ensemble = self.ensemble;
end
