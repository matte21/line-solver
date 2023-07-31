% Finds the response times along each path leading out of start until endNode
function ri = mva_fj_find_paths(sn, P, start, endNode, r, s, QN, TN, currentTime)
    if start == endNode
        % Add the current response time of the parallel branch to the list, but subtract the synchronisation time
        qLen = QN(sn.nodeToStation(start), r) + QN(sn.nodeToStation(start), s);
        tput = TN(sn.nodeToStation(start), r) + TN(sn.nodeToStation(start), s);
        ri = currentTime - qLen / tput;
        return
    end
    ri = [];
    for i=find(P(start, :))
        qLen = 0;
        tput = 1;
        if ~isnan(sn.nodeToStation(i))
            qLen = QN(sn.nodeToStation(i), r) + QN(sn.nodeToStation(i), s);
            tput = TN(sn.nodeToStation(i), r) + TN(sn.nodeToStation(i), s);
        end
        ri = [ri, mva_fj_find_paths(sn, P, i, endNode, r, s, QN, TN, currentTime + qLen/tput)];
    end
end