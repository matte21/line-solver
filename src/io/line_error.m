function line_error(caller,errmsg)
% LINE_ERROR(CALLER, ERRMSG)

% Copyright (c) 2012-2023, Imperial College London
% All rights reserved.
%try
x=dbstack;
error('[%s.m@%d] %s',caller,x(2).line,errmsg);
%catch ME
%    throwAsCaller(ME)
%end
end
