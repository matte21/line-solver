global LINEStdOut
global LINEVerbose
global LINEVersion
global LINEDoChecks
global LINECoarseTol % Coarse tolerance for comparing averages, weights, states
global LINEFineTol % Fine tolerance eg for distribution comparisons
global LINEInf % Generic representation of infinity
global BuToolsVerbose
global BuToolsCheckInput
global BuToolsCheckPrecision

% keep this block here
cwd = fileparts(mfilename('fullpath'));
addpath(genpath(cwd));
format compact
warning ON BACKTRACE

% assign global constants
LINEStdOut = 1; % console
LINEVersion = '2.0.25';
LINEVerbose = VerboseLevel.NORMAL;
LINEDoChecks = true;
LINECoarseTol = 1e-3; 
LINEFineTol = 1e-8; 
LINEInf = 1/LINEFineTol; 

fprintf(1,'Starting LINE version %s: ',LINEVersion);
switch LINEStdOut
    case 1
    fprintf(1,'StdOut=console, ');
end 
switch LINEVerbose
    case VerboseLevel.NORMAL
    fprintf(1,'VerboseLevel=NORMAL, ');
    case VerboseLevel.DEBUG
    fprintf(1,'VerboseLevel=DEBUG, ');
    case VerboseLevel.DISABLED
    fprintf(1,'VerboseLevel=DISABLED, ');    
end
if LINEDoChecks
    fprintf(1,'DoChecks=true, ');
else
    fprintf(1,'DoChecks=false, ');
end
fprintf(1,'CoarseTol=%x, ',LINECoarseTol);
fprintf(1,'FineTol=%x\n',LINEFineTol);

BuToolsVerbose = false;
BuToolsCheckInput = true;
BuToolsCheckPrecision = LINEFineTol;
