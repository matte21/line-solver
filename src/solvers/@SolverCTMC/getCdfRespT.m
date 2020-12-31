function RD = getCdfRespT(self, R)
% RD = GETCDFRESPT(R)

if ~exist('R','var')
    R = getAvgRespTHandles(self);
end
qn = self.getStruct;
RD = cell(qn.nstations, qn.nclasses);
M = qn.nstations;
K = qn.nclasses;
for i=1:M
    for r=1:K
        if ~R{i,r}.disabled
            [i,r]
            if  isempty(self.model.stations{i}.server.serviceProcess{r}) || self.model.stations{i}.server.serviceProcess{r}{end}.isDisabled
                 % noop
            else                
                % tag a class-r job
                taggedModel = self.model.copy;
                taggedModel.resetNetwork;
                taggedModel.reset;
                
                Plinked = taggedModel.getLinkedRoutingMatrix;
                if ~iscell(Plinked)
                    line_error(mfilename, 'getCdfRespT requires the original model to be linked with a routing matrix defined as a cell array P{r,s} for every class pair (r,s).');
                else
                    for s=1:(K+1)
                        Plinked{s,K+1} = zeros(M);
                        Plinked{K+1,s} = zeros(M);
                    end
                    Plinked{K+1,K+1}(i,i)=1; % self-looping class
                end
                
                taggedModel.classes{end+1,1} = taggedModel.classes{r}.copy;
                if isfinite(qn.njobs(r)) % what if Nr=1 ?
                    taggedModel.classes{r}.population = taggedModel.classes{r}.population - 1;
                    taggedModel.classes{end,1}.population = 1;
                end
                
                for m=1:length(taggedModel.nodes)
                    taggedModel.stations{m}.output.outputStrategy{end+1} = taggedModel.stations{m}.output.outputStrategy{r};
                end
                
                for m=1:length(taggedModel.stations)                                        
                    if self.model.stations{m}.server.serviceProcess{r}{end}.isDisabled
                        taggedModel.stations{m}.input.inputJobClasses(1,end+1) = {[]};
                        taggedModel.stations{m}.server.serviceProcess{end+1} = taggedModel.stations{m}.server.serviceProcess{r};
                        taggedModel.stations{m}.server.serviceProcess{end}{end}=taggedModel.stations{m}.server.serviceProcess{end}{end}.copy;
                        taggedModel.stations{m}.schedStrategyPar(end+1) = 0;
                        taggedModel.stations{m}.classCap(r) = 0;
                        taggedModel.stations{m}.classCap(1,end+1) = 0;
                    else
                        taggedModel.stations{m}.input.inputJobClasses(1,end+1) = {taggedModel.stations{m}.input.inputJobClasses{1,r}};
                        taggedModel.stations{m}.server.serviceProcess{end+1} = taggedModel.stations{m}.server.serviceProcess{r};
                        taggedModel.stations{m}.server.serviceProcess{end}{end}=taggedModel.stations{m}.server.serviceProcess{end}{end}.copy;
                        taggedModel.stations{m}.schedStrategyPar(end+1) = taggedModel.stations{m}.schedStrategyPar(r);
                        taggedModel.stations{m}.classCap(r) = taggedModel.stations{m}.classCap(r) - 1;
                        taggedModel.stations{m}.classCap(1,end+1) = 1;                        
                    end
                end                                
                                
                taggedModel.link(Plinked);
                
                [Qir,Fir,ev] = SolverCTMC(taggedModel).getGenerator(true);
                
                for v=1:length(ev)
                    if ev{v}.passive{1}.event == EventType.ID_ARV && ev{v}.passive{1}.class == r && ev{v}.passive{1}.node == i
                        Air = Fir{v};
                    end
                end
                
                for v=1:length(ev)
                    if ev{v}.active{1}.event == EventType.ID_DEP && ev{v}.passive{1}.class == r && ev{v}.active{1}.node == i
                        Dir = Fir{v};
                    end
                end
                
                A = map_normalize({Qir-Air, Air});
                pie_arv = map_pie(A); % state seen upon arrival of a class-r job
                D = map_normalize({Qir-Dir, Dir});
                
                nonZeroRates = abs(Qir(Qir~=0));
                nonZeroRates = nonZeroRates( nonZeroRates >Distrib.Tol );
                T = abs(100/min(nonZeroRates)); % solve ode until T = 100 events with the slowest rate
                dT = T/100; % solve ode until T = 100 events with the slowest rate
                tset = dT:dT:T;
                
                RD{i,r} = zeros(length(tset),2);
                for t=1:length(tset)
                    RD{i,r}(t,2) = tset(t);
                    RD{i,r}(t,1) = 1-pie_arv * expm(D{1}*tset(t)) * ones(length(D{1}),1);
                end
            end
        end
    end
end

end