classdef Copyable < handle
    % Copyable allows to perform deep-copy of objects via the copy() method.
    %
    % Copyright (c) 2012-2023, Imperial College London
    % All rights reserved.

    methods
        function newObj = copy(obj)
            % NEWOBJ = COPY(OBJ)

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
