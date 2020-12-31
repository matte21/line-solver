function [infGen, eventFilt, ev] = getSymbolicGenerator(self)
if ~isdeployed
    [~, F] = getGenerator(self);
    infGen = sym(zeros(size(F{1})));
    eventFilt = cell(1, length(F));
    for e = 1:length(F)
        F{e} = full(F{e});
        minF = min(min(F{e}(F{e}>0)));
        if ~isempty(minF)
            F{e} = F{e} / minF;
            eventFilt{e} = F{e} * sym(['x',num2str(e)],'real');
            infGen = infGen + eventFilt{e};
        end
    end
    infGen = ctmc_makeinfgen(infGen);
    ev = self.getStruct.sync;
else
    infGen = [];
    eventFilt = [];
    ev = [];
end
end