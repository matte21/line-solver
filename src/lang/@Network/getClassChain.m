function chain = getClassChain(self, jobClass)
% C = GETCLASSCHAININDEX(JOBCLASS)
% C = GETCLASSCHAININDEX(CLASSNAME)

if ischar(jobClass)
    className = jobClass;
else
    className = jobClass.getName;
end

chains = self.getChains;
for c = 1:length(chains)
    if any(cell2mat(strfind(chains{c}.classnames,className)))
        chain = chains{c};
        return
    end
end
chain = [];
end