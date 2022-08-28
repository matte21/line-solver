function updateMetrics(self, it)
lqn = self.lqn;

ensemble = self.ensemble;

switch self.getOptions.method
    case 'default'
        % first obtain svct of activities at hostlayers
        self.svct = zeros(self.lqn.nidx,1);
        for r=1:size(self.svctmap,1)
            idx = self.svctmap(r,1);
            aidx = self.svctmap(r,2);
            nodeidx = self.svctmap(r,3);
            classidx = self.svctmap(r,4);

            hidx = lqn.parent(lqn.parent(aidx)); % host idx
            sn = ensemble{self.idxhash(hidx)}.getStruct(false);

            % rescale the entries so they have unit visit relatively to the refclass
            %aidxchain = find(sn.chains(:,classidx)>0);
            %refclass = sn.refclass(aidxchain);
            %Vtask = sn.visits{aidxchain}(1,refclass);
            %Ventry = sn.visits{aidxchain}(2,classidx);
            
            self.svct(aidx) = self.results{end,self.idxhash(idx)}.WN(nodeidx,classidx);% * Vtask / Ventry; % residT
            self.tput(aidx) = self.results{end,self.idxhash(idx)}.TN(nodeidx,classidx);
            self.svctproc{aidx} = Exp.fitMean(self.svct(aidx));
            self.tputproc{aidx} = Exp.fitRate(self.tput(aidx));
        end

        % estimate call response times at hostlayers
        self.callresidt = zeros(self.lqn.ncalls,1);
        for r=1:size(self.callresidtmap,1)
            idx = self.callresidtmap(r,1);
            cidx = self.callresidtmap(r,2);
            nodeidx = self.callresidtmap(r,3);
            classidx = self.callresidtmap(r,4);
            if nodeidx == 1
                self.callresidt(cidx) = 0;
            else
                self.callresidt(cidx) = self.results{end, self.idxhash(idx)}.WN(nodeidx,classidx); % residT%, includes mean number of calls already
            end
        end

        % then resolve the entry svct summing up these contributions
        entry_svct = self.svctmatrix*[self.svct;self.callresidt]; % Sum the residT of all the activities connected to this entry
        entry_svct(1:self.lqn.eshift) = 0;
        % this block fixes the problem that ResidT is scaled so that the
        % task as Vtask=1, but in call svct the entries need to have Ventry=1
        for eidx=(lqn.eshift+1):(lqn.eshift+lqn.nentries)
            tidx = lqn.parent(eidx); % task of entry
            hidx = lqn.parent(tidx); %host of entry
            % eidxname = lqn.names{eidx};
            % get class in host layer of task and entry
            tidxclass = ensemble{self.idxhash(hidx)}.attribute.tasks(find(ensemble{self.idxhash(hidx)}.attribute.tasks(:,2) == tidx),1);
            eidxclass = ensemble{self.idxhash(hidx)}.attribute.entries(find(ensemble{self.idxhash(hidx)}.attribute.entries(:,2) == eidx),1);
            task_tput  = sum(self.results{end,self.idxhash(hidx)}.TN(ensemble{self.idxhash(hidx)}.attribute.clientIdx,tidxclass));
            entry_tput = sum(self.results{end,self.idxhash(hidx)}.TN(ensemble{self.idxhash(hidx)}.attribute.clientIdx,eidxclass));
            self.svct(eidx) = entry_svct(eidx) * task_tput / entry_tput;
        end
        %self.svct(lqn.eshift+1:lqn.eshift+lqn.nentries) = entry_svct(lqn.eshift+1:lqn.eshift+lqn.nentries);
        entry_svct((self.lqn.ashift+1):end) = 0;
        for r=1:size(self.callresidtmap,1)
            cidx = self.callresidtmap(r,2);
            eidx = self.lqn.callpair(cidx,2);
            self.svctproc{eidx} = Exp.fitMean(self.svct(eidx));
        end

        % determine call response times processes
        for r=1:size(self.callresidtmap,1)
            cidx = self.callresidtmap(r,2);
            eidx = self.lqn.callpair(cidx,2);
            if it==1
                % note that respt is per visit, so number of calls is 1
                self.callresidt(cidx) = self.svct(eidx);
                self.callresidtproc{cidx} = self.svctproc{eidx};
            else
                % note that respt is per visit, so number of calls is 1
                self.callresidtproc{cidx} = Exp.fitMean(self.callresidt(cidx));
            end
        end

    case 'moment3'
        % this moment propagates through the layers 3 moments of the
        % response time distribution computed from the CDF obtained by the
        % solvers of the individual layers. In the present implementation, 
        % calls are still assumed to be exponentially distributed.
        if self.hasConverged == 0
            % first obtain svct of activities at hostlayers
            self.svct = zeros(self.lqn.nidx,1);
            for r=1:size(self.svctmap,1)
                idx = self.svctmap(r,1);
                aidx = self.svctmap(r,2);
                nodeidx = self.svctmap(r,3);
                classidx = self.svctmap(r,4);
                self.svct(aidx) = self.results{end,self.idxhash(idx)}.RN(nodeidx,classidx);
                %self.svct(aidx) = self.results{end,self.idxhash(idx)}.WN(nodeidx,classidx);
                self.tput(aidx) = self.results{end,self.idxhash(idx)}.TN(nodeidx,classidx);
                self.svctproc{aidx} = Exp.fitMean(self.svct(aidx));
            end

            % estimate call response times at hostlayers
            self.callresidt = zeros(self.lqn.ncalls,1);
            for r=1:size(self.callresidtmap,1)
                idx = self.callresidtmap(r,1);
                cidx = self.callresidtmap(r,2);
                nodeidx = self.callresidtmap(r,3);
                classidx = self.callresidtmap(r,4);
                %             self.callresidt(cidx) = self.results{end, self.idxhash(idx)}.RN(nodeidx,classidx);
                if nodeidx == 1
                    self.callresidt(cidx) = 0;
                else
                    self.callresidt(cidx) = self.results{end, self.idxhash(idx)}.RN(nodeidx,classidx);
                    %self.callresidt(cidx) = self.results{end, self.idxhash(idx)}.WN(nodeidx,classidx);
                end
            end

            % then resolve the entry svct summing up these contributions
            entry_svct = (eye(self.lqn.nidx+self.lqn.ncalls)-self.svctmatrix)\[self.svct;self.callresidt];
            entry_svct(1:self.lqn.eshift) = 0;
            self.svct(lqn.eshift+1:lqn.eshift+lqn.nentries) = entry_svct(lqn.eshift+1:lqn.eshift+lqn.nentries);
            entry_svct((self.lqn.ashift+1):end) = 0;
            for r=1:size(self.callresidtmap,1)
                cidx = self.callresidtmap(r,2);
                eidx = self.lqn.callpair(cidx,2);
                self.svctproc{eidx} = Exp.fitMean(self.svct(eidx));
            end

            % determine call response times processes
            for r=1:size(self.callresidtmap,1)
                cidx = self.callresidtmap(r,2);
                eidx = self.lqn.callpair(cidx,2);
                if it==1
                    % note that respt is per visit, so number of calls is 1
                    self.callresidt(cidx) = self.svct(eidx);
                    self.callresidtproc{cidx} = self.svctproc{eidx};
                else
                    % note that respt is per visit, so number of calls is 1
                    self.callresidtproc{cidx} = Exp.fitMean(self.callresidt(cidx));
                end
            end
        else
            self.svctcdf = cell(self.lqn.nidx,1);
            repo = [];

            % first obtain svct of activities at hostlayers
            self.svct = zeros(self.lqn.nidx,1);
            for r=1:size(self.svctmap,1)
                idx = self.svctmap(r,1);
                aidx = self.svctmap(r,2);
                nodeidx = self.svctmap(r,3);
                classidx = self.svctmap(r,4);
                self.tput(aidx) = self.results{end,self.idxhash(idx)}.TN(nodeidx,classidx);

                submodelidx = self.idxhash(idx);
                if submodelidx>length(repo)
                    try
                        repo{submodelidx} = self.solvers{submodelidx}.getCdfRespT;
                    catch me
                        switch me.identifier
                            case 'MATLAB:class:undefinedMethod'
                                line_warning(mfilename,'The solver for layer %d does not allow response time distribution calculation, switching to fluid solver.');
                                repo{submodelidx} = SolverFluid(ensemble{submodelidx}).getCdfRespT;
                        end
                    end
                end
                self.svctcdf{aidx} =  repo{submodelidx}{nodeidx,classidx};
            end

            self.callresidtcdf = cell(self.lqn.ncalls,1);

            % estimate call response times at hostlayers
            self.callresidt = zeros(self.lqn.ncalls,1);
            for r=1:size(self.callresidtmap,1)
                idx = self.callresidtmap(r,1);
                cidx = self.callresidtmap(r,2);
                nodeidx = self.callresidtmap(r,3);
                classidx = self.callresidtmap(r,4);

                submodelidx = self.idxhash(idx);
                if submodelidx>length(repo)
                    %             repo{submodelidx} = self.solvers{submodelidx}.getCdfRespT;
                    try
                        repo{submodelidx} = self.solvers{submodelidx}.getCdfRespT;
                    catch
                        repo{submodelidx} = [0,0;0.5,0;1,0]; % ??
                    end
                end
                %         self.callresidtcdf{cidx} =  repo{submodelidx}{nodeidx,classidx};
                try
                    self.callresidtcdf{cidx} =  repo{submodelidx}{nodeidx,classidx};
                catch
                    self.callresidtcdf{cidx} =  repo{submodelidx};
                end
            end
            self.cdf = [self.svctcdf;self.callresidtcdf];

            % then resolve the entry svct summing up these contributions
            matrix = inv((eye(self.lqn.nidx+self.lqn.ncalls)-self.svctmatrix));
            for i = 1:1:lqn.nentries
                eidx = lqn.eshift+i;
                convolidx = find(matrix(eidx,:)>0);
                convolidx(find(convolidx<=lqn.eshift+lqn.nentries))=[];
                num = 0;
                ParamCell = {};
                while num<length(convolidx)
                    fitidx = convolidx(num+1);
                    [m1,m2,m3,~,~] = EmpiricalCDF(self.cdf{fitidx}).getRawMoments; %% ??
                    if m1>Distrib.Zero
                        fitdist = APH.fitRawMoments(m1,m2,m3);
                        rep_num = floor(matrix(eidx,fitidx));
                        fitparam{1} = fitdist.params{1}.paramValue;
                        fitparam{2} = fitdist.params{2}.paramValue;
                        behindDecimal = matrix(eidx,fitidx)-rep_num;
                        if behindDecimal == 0
                            ParamCell = [ParamCell,repmat(fitparam,1,rep_num)];
                        elseif rep_num>0 && behindDecimal>0
                            ParamCell = [ParamCell,repmat(fitparam,1,rep_num)];
                            zerodist = APH.fitMeanAndSCV(Distrib.Zero,0.99);
                            zeroparam{1} = zerodist.params{1}.paramValue;
                            zeroparam{2} = zerodist.params{2}.paramValue;
                            [fitparam{1},fitparam{2}] = aph_simplify(fitparam{1},fitparam{2},zeroparam{1},zeroparam{2},behindDecimal,1-behindDecimal,3);
                            ParamCell = [ParamCell,fitparam];
                        else
                            zerodist = APH.fitMeanAndSCV(Distrib.Zero,0.99);
                            zeroparam{1} = zerodist.params{1}.paramValue;
                            zeroparam{2} = zerodist.params{2}.paramValue;
                            [fitparam{1},fitparam{2}] = aph_simplify(fitparam{1},fitparam{2},zeroparam{1},zeroparam{2},behindDecimal,1-behindDecimal,3);
                            ParamCell = [ParamCell,fitparam];
                        end
                        if fitidx <= self.lqn.nidx
                            self.svctproc{fitidx} = Exp.fitMean(m1);
                            self.svct(fitidx) = m1;
                        else
                            self.callresidtproc{fitidx-self.lqn.nidx} = Exp.fitMean(m1);
                            self.callresidt(fitidx-self.lqn.nidx) = m1;
                        end
                    end
                    num = num+1;
                end
                if isempty(ParamCell)
                    self.svct(eidx) = 0;
                else
                    [alpha,T] = aph_convseq(ParamCell);
                    entry_dist = APH(alpha,T);
                    self.entryproc{eidx-(lqn.nhosts+lqn.ntasks)} = entry_dist;
                    self.svct(eidx) = entry_dist.getMean;
                    self.svctproc{eidx} = Exp.fitMean(self.svct(eidx));
                    self.entryCdfRespT{eidx-(lqn.nhosts+lqn.ntasks)} = entry_dist.evalCDF;
                end
            end

            % determine call response times processes
            for r=1:size(self.callresidtmap,1)
                cidx = self.callresidtmap(r,2);
                eidx = self.lqn.callpair(cidx,2);
                if it==1
                    self.callresidt(cidx) = self.svct(eidx);
                    self.callresidtproc{cidx} = Exp.fitMean(self.svct(eidx));
                end
            end
        end
end
self.ensemble = ensemble;
end