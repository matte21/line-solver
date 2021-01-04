function bool = snHasMultiServer(qn)
% BOOL = SNHASMULTISERVER()

bool = any(qn.nservers(isfinite(qn.nservers)) > 1);
end