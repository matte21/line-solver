function solver = chooseSolver(self, method)
% SOLVER = CHOOSESOLVER(METHOD)

switch self.options.method
    case 'default'
        solver = chooseSolverHeur(self, method);
    case 'ai'
        solver = chooseSolverAI(self, method);
end
end
