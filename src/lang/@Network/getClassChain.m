function c = getClassChain(self, className)
% C = GETCLASSCHAIN(CLASSNAME)

chains = self.getChains;
if ischar(className)
    for c = 1:length(chains)
        if any(cell2mat(strfind(chains{c}.classnames,className)))
            return
        end
    end
else
    for c = 1:length(chains)
        if any(cell2mat(chains{c}.index==1))
            return
        end
    end
end
c = -1;
end