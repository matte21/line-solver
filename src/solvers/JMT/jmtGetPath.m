function jmtPath = jmtGetPath
% JMTPATH = JMTGETPATH

% Copyright (c) 2012-2020, Imperial College London
% All rights reserved.

jmtPath = fileparts(which('JMT.jar'));
if isempty(jmtPath)
    fprintf(1,'\nJava Modelling Tools cannot be found.\nLINE will try to download the latest JMT version.\n')
    jmtSolverFolder = fileparts(mfilename('fullpath'));
    m = input('Do you want to continue (download approx. 30MB), Y/N [N]: ','s');
    if m=='Y'
        fprintf(1,'Download started, please be patient this may take several minutes.\n')
        if exist('websave')==2
            if ispc
                outfilename = websave([jmtSolverFolder,'\JMT.jar'],'http://jmt.sourceforge.net/latest/JMT.jar');
            else
                outfilename = websave([jmtSolverFolder,'/JMT.jar'],'http://jmt.sourceforge.net/latest/JMT.jar');
            end
            fprintf(1,'Download completed. JMT jar now located at: %s\n',outfilename);
        elseif isoctave
            if ispc
                outfilename = urlwrite('http://jmt.sourceforge.net/latest/JMT.jar', [jmtSolverFolder,'\JMT.jar']);
            else
                outfilename = urlwrite('http://jmt.sourceforge.net/latest/JMT.jar', [jmtSolverFolder,'/JMT.jar']);
            end
            fprintf(1,'Download completed. JMT jar now located at: %s\n',outfilename);
        else
            error('The MATLAB version is too old and JMT cannot be downloaded automatically. Please download http://jmt.sourceforge.net/latest/JMT.jar and put it under "bin\solvers\JMT\".\n');
        end
        jmtPath = fileparts(which('JMT.jar'));
    else
        if ispc
            error('Java Modelling Tools was not found. Please download http://jmt.sourceforge.net/latest/JMT.jar and put it under "bin\line\src\solvers\JMT\".\n');
        else
            error('Java Modelling Tools was not found. Please download http://jmt.sourceforge.net/latest/JMT.jar and put it under "bin/line/src/solvers/JMT/".\n');
        end
    end
end
end
