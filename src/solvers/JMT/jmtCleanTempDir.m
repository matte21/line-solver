pd = pwd;
cwd = fullfile(tempdir,'jsim');
cd(cwd)
delete *.jsim
delete *.jsim-result.jsim
cwd = fullfile(tempdir,'jmva');
cd(cwd)
delete *.jmva
delete *.jmva-result.jsim
cd(pd)
