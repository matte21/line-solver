function P = getLinkedRoutingMatrix(self)
% P = GETLINKEDROUTINGMATRIX()
if isempty(self.linkedRoutingTable)
    line_warning(mfilename,'Unsupported: getLinkedRoutingMatrix() reqyires that the model topology has been instantiated with the link() method. Attempting auto-recovery.');
    fname = tempname;
    QN2SCRIPT(self,self.name,fname);
    run(fname);
    delete(fname);
    P = model.getLinkedRoutingMatrix();
    % THE MODEL TOPOLOGY MUST HAVE BEEN LINKED WITH THE LINK() METHOD.');
else
    P = self.linkedRoutingTable;
end
end