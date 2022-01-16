function jpar = exportJava(par)
if ~iscell(par) % first assume that par is not a cell array
    if length(par)==1 % scalar
        if islogical(par)
            jpar = java.lang.Boolean(par);
        elseif isnumeric(par)
            jpar = java.lang.Double(par);
        elseif isa(par,'function_handle')
            jpar = java.lang.String(func2str(par));
        elseif ischar(par) || isstring(par) % single-character strings
            jpar = java.lang.String(par);
        end
    elseif length(size(par))==2 && min(size(par))==1 % 1d vector
        if all(islogical(par))
            jpar = javaArray('java.lang.Boolean',length(par));
            for j=1:length(par)
                jpar(j) = java.lang.Boolean(par(j));
            end
        elseif all(isnumeric(par))
            jpar = javaArray('java.lang.Double',length(par));
            for j=1:length(par)
                jpar(j) = java.lang.Double(par(j));
            end
        elseif all(ischar(par)) || all(isstring(par))
            jpar = java.lang.String(par);
        elseif all(isa(par,'function_handle'))
            jpar = javaArray('java.lang.String',length(par));
            for j=1:length(par)
                jpar(j) = java.lang.String(func2str(par(j)));
            end
        end
    elseif length(size(par))==2 % 2d matrix
        if all(islogical(par))
            jpar = javaArray('java.lang.Boolean',size(par,1),size(par,2));
            for i=1:size(par,1)
                for j=1:size(par,1)
                    jpar(i,j) = java.lang.Boolean(par(i,j));
                end
            end
        elseif all(isnumeric(par))
            jpar = javaArray('java.lang.Double',size(par,1),size(par,2));
            for i=1:size(par,1)
                for j=1:size(par,1)
                    jpar(i,j) = java.lang.Double(par(i,j));
                end
            end
        end
    end
elseif iscell(par)
    % jpar.get('i,j') returns the cell element at position i,j. i and j
    %                 both start at 0
    jpar = javaObject('java.util.HashMap'); % generic list of objects
    % we assume the cell elements to be homogeneous
    if length(par)==1 % scalar cell
        jpar.put('0',exportJava(par{1}));
    elseif length(size(par))==2 % 1d or 2d matrix cell
        for i=1:size(par,1)
            for j=1:size(par,2)
                jpar.put(sprintf('%d,%d',i-1,j-1),exportJava(par{i,j}));
            end
        end
    end
else
    line_error('Unsupported conversion');
end
end