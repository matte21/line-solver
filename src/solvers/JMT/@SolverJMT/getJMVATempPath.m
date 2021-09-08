function out = getJMVATempPath(self)
% OUT = GETJMVATEMPPATH()

fname = [getFileName(self), ['.', 'jmva']];
out = [self.filePath,'jmva',filesep, fname];
end
