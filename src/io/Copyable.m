classdef Copyable < handle
    % Copyable allows to perform deep-copy of objects via the copy() method.
    %
    % Copyright (c) 2012-2022, Imperial College London
    % All rights reserved.
    
    methods
        function newObj = copy(obj)
            % NEWOBJ = COPY(OBJ)
            
            if isoctave % or matlab versions less than 7.11
                % Other - serialize via temp file (slower)
                fname = [lineTempName '.mat'];
                save(fname, 'obj');
                newObj = load(fname);
                newObj = newObj.obj;
                delete(fname);
            else
                try
                    % MATLAB R2010b or newer - directly in memory (faster)
                    objByteArray = getByteStreamFromArray(obj);
                    newObj = getArrayFromByteStream(objByteArray);
                catch ME
                    fname = [lineTempName '.mat'];
                    save(fname, 'obj');
                    newObj = load(fname);
                    newObj = newObj.obj;
                    delete(fname);                    
                end
            end
        end
    end
    
end
