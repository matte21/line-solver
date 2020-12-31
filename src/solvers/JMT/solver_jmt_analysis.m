%@todo unfinished
function [QN,UN,RN,TN,CN,XN,runtime] = solver_jmt_analysis(qn, options)
self.writeJSIM;
cmd = ['java -cp "',getJMTJarPath(self),filesep,'JMT.jar" jmt.commandline.Jmt sim "',getFilePath(self),'jsim',filesep,getFileName(self),'.jsim" -seed ',num2str(options.seed),' --illegal-access=permit'];
if options.verbose
    line_printf('\nJMT model: %s',[getFilePath(self),'jsim',filesep,getFileName(self),'.jsim']);
    line_printf('\nJMT command: %s',cmd);
end
[~, result] = system(cmd);
runtime = toc(Tstart);
self.getResults;
end