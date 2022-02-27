function U = getServiceMatrixRecursion(self, lqn, aidx, eidx, U)
% auxiliary function to getServiceMatrix
nextaidxs = find(lqn.graph(aidx,:));
G = double(full(lqn.graph)>0); % connection matrix between LQN elements
for nextaidx = nextaidxs
    if ~isempty(nextaidx)
        if ~(lqn.parent(aidx) == lqn.parent(nextaidx))
            %% if the successor activity is a call
            for cidx = lqn.callsof{aidx}
                switch lqn.calltype(cidx)
                    case CallType.ID_SYNC
                        U(eidx,lqn.nidx+cidx) = 1;%lqn.callproc{cidx}.getMean;
                    case CallType.ID_ASYNC
                        % nop - doesn't contribute to respt
                end
            end
        end
        % here we have processed all calls, let us do the activities now
        %% if the successor activity is not a call
        if (lqn.parent(aidx) == lqn.parent(nextaidx))
            if nextaidx ~= aidx
                eidx=full(eidx);
                U(eidx,nextaidx) = U(eidx,nextaidx) + G(aidx,nextaidx); % self-loops not included as already accounted in visits
            %% now recursively build the rest of the routing matrix graph
                U = self.getServiceMatrixRecursion(lqn, nextaidx, eidx, U);
            end
        end
    end
end % nextaidx
end
