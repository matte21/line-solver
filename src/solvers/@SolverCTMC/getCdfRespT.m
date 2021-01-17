function RD = getCdfRespT(self, R)
% RD = GETCDFRESPT(R)

if nargin<2 %~exist('R','var')
    R = getAvgRespTHandles(self);
end
sn = self.getStruct;
RD = cell(sn.nstations, sn.nclasses);
M = sn.nstations;
K = sn.nclasses;
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
                taggedModel.reset(true);
                
                Plinked = taggedModel.getLinkedRoutingMatrix;
                if ~iscell(Plinked)
                    line_error(mfilename, 'getCdfRespT requires the original model to be linked with a routing matrix defined as a cell array P{r,s} for every class pair (r,s).');
                else
                    for s=1:(K+1)
                        Plinked{s,K+1} = Plinked{s,r};
                        Plinked{K+1,s} = Plinked{r,s};
                    end
                end
                
                taggedModel.classes{end+1,1} = taggedModel.classes{r}.copy;
                taggedModel.classes{end,1}.index=length(taggedModel.classes);                
                taggedModel.classes{r,1}.name=[taggedModel.classes{r,1}.name,'.tagged'];
                %if isfinite(sn.njobs(r)) && sn.njobs(r)>1 % make class r with a single job now
                taggedModel.classes{r}.population = 1;
                taggedModel.classes{end,1}.population = taggedModel.classes{end}.population - 1;
                %end
                
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
                        taggedModel.stations{m}.classCap(1,end+1) = taggedModel.stations{m}.classCap(r) - 1;
                        taggedModel.stations{m}.classCap(r) = 1;
                    end
                end
                
                taggedModel.refreshStruct(true);
                %snt = taggedModel.getStruct
                %keyboard
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