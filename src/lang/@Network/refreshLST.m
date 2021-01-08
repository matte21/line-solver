function [lt] = refreshLST(self,statSet,classSet)
% [LT] = REFRESHLAPLST(STATSET,CLASSSET)
% Refresh the Laplace-Stieltjes transforms in the NetworkStruct object

% Copyright (c) 2012-2021, Imperial College London
% All rights reserved.

M = getNumberOfStations(self);
K = getNumberOfClasses(self);
if nargin<2
    statSet = 1:M;
    classSet = 1:K;
elseif nargin==2
    classSet = 1:K;
elseif nargin==3 && isfield(self.sn,'lt')
    % we are only updating selected stations and classes so use the
    % existing ones for the others
    lt = self.sn.lt;
else
    lt = cell(M,K);
end

source_i = self.getIndexSourceStation;
for i=statSet
    for r=classSet
        if i == source_i
            if  isa(self.stations{i}.input.sourceClasses{r}{end},'Disabled')
                lt{i,r} = [];
            else
                lt{i,r} = @(s) self.stations{i}.arrivalProcess{r}.evalLST(s);
            end
        else
            switch class(self.stations{i})
                case {'Fork'}
                    lt{i,r} = [];
                case {'Join'}
                    lt{i,r} = [];
                otherwise
                    lt{i,r} = @(s) self.stations{i}.serviceProcess{r}.evalLST(s);
            end
        end
    end
end
if ~isempty(self.sn) %&& isprop(self.sn,'mu')
    self.sn.lst = lt;
end
end
