function r = isoctave ()
% r = ISOCTAVE()
% Return true if the execution environment is GNU Octave
%
% Copyright (c) 2012-2021, Imperial College London
% All rights reserved.
  persistent x;
  if (isempty (x))
    x = exist ('OCTAVE_VERSION', 'builtin');
  end
  r = x;
end
