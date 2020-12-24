function v=cellisclass(c,className)
% s=CELLISCLASS(c,class)
% Check if cell elements belong to class
%
% Copyright (c) 2012-2020, Imperial College London
% All rights reserved.

v=cellfun('isclass',c,className);
end