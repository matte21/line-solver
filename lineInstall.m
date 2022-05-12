w=warning('query');
warning on
disp('Checking java...')
[status,result] = system('java');
hasWarnings = false;
if result == 0
    error('ERROR: the Java Runtime Environment is not installed, this is required for LINE.')
end
disp('Checking MATLAB dependencies...')
if license('test','statistics_toolbox')==0
    error('ERROR: the Statistics and Machine Learning toolbox is not installed, this is required for LINE.')
end
if license('test','optimization_toolbox')==0
    error('ERROR: the Optimization Toolbox is not installed, this is required for LINE.')
end
if license('test','gads_toolbox')==0
    warning('The Global Optimization Toolbox is not installed, this is required for LINE.')
    hasWarnings = true;
end
if license('test','symbolic_toolbox')==0
    warning('The Symbolic Toolbox is not installed, this may be required by some LINE methods.')
    hasWarnings = true;
end
disp('Checking LQNS...')
[status,result] = system('lqns --h');
if result == 0
    warning('WARNING: LQNS is not installed, this may be required by some LINE methods.')
    hasWarnings = true;
end
disp('Checking JMT...')
jmtGetPath;
warning(w);
if hasWarnings
    disp('Completed. LINE has warnings.')
else
    disp('Success. LINE is ready to use.')
end