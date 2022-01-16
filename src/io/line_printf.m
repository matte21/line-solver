function line_printf(MSG,varargin)
% LINE_PRINTF(MSG, VARARGIN)

% Copyright (c) 2012-2022, Imperial College London
% All rights reserved.

if isoctave
    fprintf(1, sprintf('%s\n',sprintf(MSG, varargin{:})));
else
    MSG = strrep(MSG,'\n','');
    MSG = strrep(MSG, '\', '\\');
    if ~contains(MSG,'...')
        if contains(MSG,'Summary')
            fprintf(1, sprintf('%s\n',sprintf(MSG, varargin{:})));
        elseif contains(MSG,'Iter')
            fprintf(1, sprintf('%s',sprintf(MSG, varargin{:})));        
        else
            fprintf(1, '%s\n', sprintf(MSG, varargin{:}));
        end
    else
        MSG = sprintf('%s',sprintf(MSG, varargin{:}));
        fprintf(1, '%s', MSG);
    end
end
end