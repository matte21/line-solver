function java_model = LINE2JLINE(line_model)
try
    import jline.*; %#ok<SIMPT>
catch
    javaaddpath(which('linesolver.jar'));
    import jline.*; %#ok<SIMPT>
end

java_model = JLINE.from_line_network(line_model);
end
