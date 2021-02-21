function line_warning(caller, MSG, varargin)
% LINE_WARNING(CALLER, ERRMSG)

% Copyright (c) 2012-2021, Imperial College London
% All rights reserved.

errmsg=sprintf(MSG, varargin{:});
w = warning('QUERY','ALL');
switch w(1).state
    case 'on'
        %warning('[%s] %s',caller,MSG);        
        %line_printf(sprintf('Warning [%s]: %s',caller,errmsg));
    case 'off'
        %line_printf(sprintf('Warning [%s]: %s',caller,errmsg));
end
end
