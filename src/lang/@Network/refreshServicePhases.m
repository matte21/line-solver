function [ph, mu, phi, phases] = refreshServicePhases(self, statSet, classSet)
% [PH, MU, PHI, PHASES] = REFRESHSERVICEPHASES()
% Obtain information about phases of service and arrival processes.

% Copyright (c) 2012-2021, Imperial College London
% All rights reserved.

M = getNumberOfStations(self);
K = getNumberOfClasses(self);
if nargin<2
    statSet = 1:M;
    classSet = 1:K;
elseif nargin==2
    classSet = 1:K;
elseif nargin==3 && isfield(self.qn, 'mu') && isfield(self.qn, 'phi') && isfield(self.qn, 'phases')
    % we are only updating selected stations and classes so use the
    % existing ones for the others
    mu = self.qn.mu;
    phi = self.qn.phi;
    phases = self.qn.phases;
else
    mu = cell(M,K);
    phi = cell(M,K);
    phases = zeros(M,K);
end

stations = self.stations;
for i=statSet
    if i == self.getIndexSourceStation
        [~,mu_i,phi_i] = stations{i}.getMarkovianSourceRates();
    else
        switch class(stations{i})
            case 'Fork'
                mu_i = cell(1,K);
                phi_i = cell(1,K);
                for r=1:K
                    mu_i{r} = NaN;
                    phi_i{r} = NaN;
                end
            case 'Join'
                mu_i = cell(1,K);
                phi_i = cell(1,K);
                for r=1:K
                    mu_i{r} = NaN;
                    phi_i{r} = NaN;
                end
            otherwise
                [~,mu_i,phi_i] = stations{i}.getMarkovianServiceRates();
        end
    end
    for r=classSet
        mu{i,r} = mu_i{r};
        phi{i,r} = phi_i{r};
        if isnan(mu_i{r}) % disabled
            phases(i,r) = 0;
        else
            phases(i,r) = length(mu_i{r});
        end
    end
end

if ~isempty(self.qn) %&& isprop(self.qn,'mu')
    self.qn.mu = mu;
    self.qn.phi = phi;
    self.qn.phases = phases;
    self.qn.phasessz = max(self.qn.phases,ones(size(self.qn.phases)));
    self.qn.phaseshift = [zeros(size(phases,1),1),cumsum(self.qn.phasessz,2)];
end
[ph, phases] = refreshMarkovianService(self);
end