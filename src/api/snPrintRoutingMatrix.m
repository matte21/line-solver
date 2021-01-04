function snPrintRoutingMatrix(qn)
% SNPRINTROUTINGMATRIX()

node_names = qn.nodenames;
classnames = qn.classnames;
rtnodes = qn.rtnodes;
nnodes = qn.nnodes;
nclasses = qn.nclasses;
for i=1:nnodes
    for r=1:nclasses
        for j=1:nnodes
            for s=1:nclasses
                if rtnodes((i-1)*nclasses+r,(j-1)*nclasses+s)>0
                    if qn.nodetype == NodeType.ID_CACHE
                        pr = 'state-dependent';
                    else
                        pr = num2str(rtnodes((i-1)*nclasses+r,(j-1)*nclasses+s),'%f');
                    end
                    line_printf('\n%s [%s] => %s [%s] : Pr=%s',node_names{i}, classnames{r}, node_names{j}, classnames{s}, pr);
                end
            end
        end
    end
end
end