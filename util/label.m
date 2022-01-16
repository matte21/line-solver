function lbl=label(varargin)
if length(varargin)==1
    cellchar = varargin{1};
    if isoctave
        lbl=cellchar;
    else
        lbl=categorical(cellchar);
    end
else
    n=varargin{1};
    m=varargin{2};
    if isoctave
        lbl=cell(n,m);
    else
        lbl=categorical(n,m);
    end
end
end