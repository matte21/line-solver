function sourceidx = getIndexSourceStation(self)
% INDEX = GETINDEXSOURCESTATION()

% Copyright (c) 2012-2020, Imperial College London
% All rights reserved.
if isempty(self.sourceidx)
    if self.hasOpenClasses()
        self.sourceidx = find(cellisa(self.stations,'Source'));
    end
end
sourceidx = self.sourceidx;
end
