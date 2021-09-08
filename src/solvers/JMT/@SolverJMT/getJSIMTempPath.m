function out = getJSIMTempPath(self)
% OUT = GETJSIMTEMPPATH()

fname = [getFileName(self), ['.', 'jsim']];
out = [self.filePath,'jsim',filesep, fname];
end