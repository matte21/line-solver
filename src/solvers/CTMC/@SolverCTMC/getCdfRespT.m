function RD = getCdfRespT(self, R)
% RD = GETCDFRESPT(R)
%global GlobalConstantsGlobalConstants.FineTol

if nargin<2 %~exist('R','var')
    R = getAvgRespTHandles(self);
end
sn = self.getStruct;
RD = cell(sn.nstations, sn.nclasses);
M = sn.nstations;
K = sn.nclasses;
N = sn.njobs;
if any(isinf(N))
    line_error(mfilename,'getCdfRespT is presently supported only for closed models.')
end
for c=1:sn.nchains    
    inchain = sn.inchain{c};
    s = inchain(N(inchain)>0); % tag a class that has non-zero jobs.
    jobclass = self.model.getClassByIndex(s);
    chain = self.model.getClassChain(jobclass);
    [taggedModel, taggedJob] = self.model.tagChain(chain,jobclass); % diminish jobclass population by 1    
    %taggedModel.stations{:}
    [Q,F,ev] = SolverCTMC(taggedModel,self.options).getGenerator(); % Q: generator, F: filtration, ev: events
    tsn = taggedModel.getStruct;
    tinchain = cell2mat(taggedJob.index);

    for i=1:M
        for ir=1:length(tinchain)
            r = tinchain(ir);
            A1 = sparse(zeros(size(F{s})));
            for r=tinchain % filter tagged job
                if taggedModel.classes{r}.completes
                    for v=1:length(ev)
                        if ev{v}.passive{1}.event == EventType.ID_ARV && ev{v}.passive{1}.class == r && ev{v}.passive{1}.node == i
                            A1 = A1 + sparse(F{v});
                        end
                    end
                end
            end

            D1 = sparse(zeros(size(F{s})));
            for r=tinchain % filter tagged job
                if taggedModel.classes{r}.completes
                    for v=1:length(ev)
                        if ev{v}.active{1}.event == EventType.ID_DEP && ev{v}.active{1}.class == r && ev{v}.active{1}.node == i
                            D1 = D1 + sparse(F{v});
                        end
                    end
                end
            end

            A = map_normalize({Q-A1, A1});
            pie_arv = map_pie(A); % state seen upon arrival of a class-r job
            D = map_normalize({Q-D1, D1});

            nonZeroRates = abs(Q(Q~=0));
            nonZeroRates = nonZeroRates( nonZeroRates > GlobalConstantsGlobalConstants.FineTol );
            T = abs(100/min(nonZeroRates)); % solve ode until T = 100 events with the slowest rate
            dT = T/100000; % solve ode until T = 100 events with the slowest rate
            tset = 0:dT:T;

            rorig = chain.index{ir};
            RD{i,rorig} = zeros(length(tset),2);
            for t=1:length(tset)
                RD{i,rorig}(t,2) = tset(t);
                RD{i,rorig}(t,1) = 1-pie_arv * expm(D{1}*tset(t)) * ones(length(D{1}),1);
                if RD{i,rorig}(t,1)>1-GlobalConstants.CoarseTol
                    RD{i,rorig}(t+1:end,:)=[];
                    break
                end
            end
        end
    end
end
end