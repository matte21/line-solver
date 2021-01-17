function met = Metric(type, class, station)
% An output metric of a Solver, such as a performance index
%
% Copyright (c) 2012-2021, Imperial College London
% All rights reserved.

if nargin > 2
    met = struct('type',type,'class',class,'station',station,'disabled',false,'transient',false);
else
    met = struct('type',type,'class',class,'station',NaN,'disabled',false,'transient',false);
end % nargin
end