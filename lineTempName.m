function tmpname = lineTempName
    tmpname = tempname([lineRootFolder,filesep,'workspace']);
    if ~exist('tmpname','dir')
        mkdir(tmpname);
    end
end