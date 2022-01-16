function ft = getForks(self, rt)
% FT = GETFORKS(RT)

% Copyright (c) 2012-2022, Imperial College London
% All rights reserved.

M = getNumberOfStations(self);
K = getNumberOfClasses(self);

ft = zeros(M*K); % fork table
for i=1:M % source
    for r=1:K % source class
        for j=1:M % dest
            switch class(self.stations{i})
                case 'Fork'
                    if rt((i-1)*K+r,(j-1)*K+r) > 0
                        ft((i-1)*K+r,(j-1)*K+r) = self.stations{i}.output.tasksPerLink;
                    end
            end
        end
    end
end
end
