function [ph, phases] = refreshMarkovianService(self)
% [PH, PHASES] = REFRESHPHSERVICE()

% Copyright (c) 2012-2021, Imperial College London
% All rights reserved.

M = getNumberOfStations(self);
K = getNumberOfClasses(self);
ph = cell(M,K);
phases = zeros(M,K);
stations = self.stations;
for i=1:M
    if i == self.getIndexSourceStation
        ph_i = stations{i}.getMarkovianSourceRates();
    else
        switch class(stations{i})
            case 'Fork'
                mu_i = cell(1,K);
                phi_i = cell(1,K);
                for r=1:K
                    mu_i{r} = NaN;
                    phi_i{r} = NaN;
                end
                ph_i = Coxian(mu_i,phi_i).getRepresentation;
            case 'Join'
                mu_i = cell(1,K);
                phi_i = cell(1,K);
                for r=1:K
                    mu_i{r} = NaN;
                    phi_i{r} = NaN;
                    ph_i{r} = Coxian(mu_i{r},phi_i{r}).getRepresentation;
                end
            otherwise
                ph_i = stations{i}.getMarkovianServiceRates();
        end
    end
    for r=1:K
        ph{i,r} = ph_i{r};
        if isempty(ph{i,r}) % fluid fails otherwise
            phases(i,r) = 1;
        elseif any(isnan(ph{i,r}{1}(:))) || any(isnan(ph{i,r}{2}(:))) % disabled
            phases(i,r) = 0;
        else
            phases(i,r) = length(ph{i,r}{1});
        end
    end
end
if ~isempty(self.qn) %&& isprop(self.qn,'mu')
	proc = ph;
	pie = cell(size(ph));
	for i=1:size(ph,1)
    	for r=1:size(ph,2)
        	map_ir = ph{i,r};
        	if ~isempty(map_ir)
				% proc{i,r} = map_normalize(map_ir);
                proc{i,r} = map_ir;
				pie{i,r} = map_pie(map_ir);
    	    else
				pie{i,r} = NaN;
    	    end
    	end
	end
	self.qn.proc = proc;
	self.qn.pie = pie;
	self.qn.phases = phases;
	self.qn.phasessz = max(self.qn.phases,ones(size(self.qn.phases)));
	self.qn.phasessz(self.qn.nodeToStation(self.qn.nodetype == NodeType.Join),:)=phases(self.qn.nodeToStation(self.qn.nodetype == NodeType.Join),:);
	self.qn.phaseshift = [zeros(size(phases,1),1),cumsum(self.qn.phasessz,2)];	
end
end
