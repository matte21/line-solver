function updateLayers(self, it)
lqn = self.lqn;
ensemble = self.ensemble;
idxhash = self.idxhash;
idletproc = self.idletproc;
svctproc = self.svctproc;
svcupdmap = self.svcupdmap;
arvupdmap = self.arvupdmap;
tputproc = self.tputproc;
callupdmap = self.callupdmap;
callresptproc = self.callresptproc;

% reassign service times
for r=1:size(svcupdmap,1)
    if mod(it, 0)
        ri = size(svcupdmap,1) - r + 1;
    else
        ri = r;
    end
    idx = svcupdmap(ri,1);
    aidx = svcupdmap(ri,2);
    nodeidx = svcupdmap(ri,3);
    classidx = svcupdmap(ri,4);
    class = ensemble{idxhash(svcupdmap(ri,1))}.classes{classidx};
    node = ensemble{idxhash(idx)}.nodes{nodeidx};
    switch nodeidx
        case  ensemble{idxhash(idx)}.attribute.clientIdx
            if lqn.type(aidx) == LayeredNetworkElement.TASK
                if lqn.schedid(aidx) ~= SchedStrategy.ID_REF
                    if ~isempty(idletproc{aidx}) % this is empty for isolated components, which can be ignored
%                        if it==1
                            node.setService(class, idletproc{aidx});
%                         else
%                             if ~node.serviceProcess{class.index}.isImmediate()
%                                 node.serviceProcess{class.index}.updateMean(idletproc{aidx}.getMean);
%                                 node.server.serviceProcess{class.index}{end}.updateMean(idletproc{aidx}.getMean);
%                             else
%                                 node.setService(class, idletproc{aidx});
%                             end
%                         end
                    end
                else
%                    if it==1
                        node.setService(class, svctproc{aidx});
%                     else
%                         if ~node.serviceProcess{class.index}.isImmediate()
%                             node.serviceProcess{class.index}.updateMean(svctproc{aidx}.getMean);
%                             node.server.serviceProcess{class.index}{end}.updateMean(svctproc{aidx}.getMean);
%                         else
%                             node.setService(class, svctproc{aidx});
%                         end
%                     end
                end
            else
%                if it==1
                    node.setService(class, svctproc{aidx});
%                 else
%                     if ~node.serviceProcess{class.index}.isImmediate() 
%                         node.serviceProcess{class.index}.updateMean(svctproc{aidx}.getMean);
%                         node.server.serviceProcess{class.index}{end}.updateMean(svctproc{aidx}.getMean);
%                     else
%                         node.setService(class, svctproc{aidx});
%                     end
%                 end
            end
        case ensemble{idxhash(idx)}.attribute.serverIdx
            node.setService(class, svctproc{aidx});
    end
end

% reassign arrival rates
for r=1:size(arvupdmap,1)
    %for r=1:0
    if mod(it, 0)
        ri = size(arvupdmap,1) - r + 1;
    else
        ri = r;
    end
    idx = arvupdmap(ri,1);
    cidx = arvupdmap(ri,2);
    nodeidx = arvupdmap(ri,3);
    classidx = arvupdmap(ri,4);
    class = ensemble{idxhash(arvupdmap(ri,1))}.classes{classidx};
    node = ensemble{idxhash(idx)}.nodes{nodeidx};
    node.setArrival(class, tputproc{lqn.callpair(cidx,1)});
end

% reassign call service time / response time
for c=1:size(callupdmap,1)
    if mod(it, 0)
        ci = size(callupdmap,1) - c + 1;
    else
        ci = c;
    end
    idx = callupdmap(ci,1);
    cidx = callupdmap(ci,2);
    nodeidx = callupdmap(ci,3);
    class = ensemble{idxhash(callupdmap(ci,1))}.classes{callupdmap(ci,4)};
    node = ensemble{idxhash(idx)}.nodes{nodeidx};
    switch nodeidx
        case ensemble{idxhash(idx)}.attribute.clientIdx % client
            node.setService(class, callresptproc{cidx});
        case ensemble{idxhash(idx)}.attribute.serverIdx % the call is processed by the server, then replace with the svc time
            eidx = lqn.callpair(cidx,2);
            %tidx = lqn.parent(eidx);
            %eidxclass = self.ensemble{self.idxhash(tidx)}.attribute.calls(find(self.ensemble{self.idxhash(tidx)}.attribute.calls(:,4) == eidx),1);
            %eidxchain = find(self.ensemble{self.idxhash(tidx)}.getStruct.chains(:,eidxclass)>0);
            %qn = self.ensemble{self.idxhash(tidx)}.getStruct;
            %svctproc{eidx}.updateMean(svctproc{eidx}.getMean * qn.visits{eidxchain}(1,qn.refclass(eidxchain)) / qn.visits{eidxchain}(2,eidxclass))
            %%task_tput = sum(self.results{end,self.idxhash(tidx)}.TN(self.ensemble{self.idxhash(tidx)}.attribute.serverIdx,eidxclass))
            %%entry_tput = sum(self.results{end,self.idxhash(tidx)}.TN(self.ensemble{self.idxhash(tidx)}.attribute.serverIdx,eidxclass))
%            if it==1
                node.setService(class, svctproc{eidx});
%             else
%                 if ~node.serviceProcess{class.index}.isImmediate()
%                     node.serviceProcess{class.index}.updateMean(svctproc{eidx}.getMean);
%                     node.server.serviceProcess{class.index}{end}.updateMean(svctproc{eidx}.getMean);
%                 else
%                     node.setService(class, svctproc{eidx});
%                 end
%             end

    end
end


%self.ensemble = ensemble;
%self.idxhash = idxhash;
%self.idletproc = idletproc;
%self.svctproc = svctproc;
%self.svcupdmap = svcupdmap;
%self.arvupdmap = arvupdmap;
%self.tputproc = tputproc;
%self.callupdmap = callupdmap;
%self.callresptproc = callresptproc;
end