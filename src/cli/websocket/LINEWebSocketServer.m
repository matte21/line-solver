classdef LINEWebSocketServer < WebSocketServer
    %ECHOSERVER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = LINEWebSocketServer(varargin)
            %Constructor
            obj@WebSocketServer(varargin{:});
        end
    end
    
    methods (Access = protected)
        function onOpen(obj,conn,message)
            fprintf('%s\n',message)
        end
        
        function onTextMessage(obj,conn,message)
            % This function sends an echo back to the client
            fname = tempname;
            fid = fopen(fname,'w+');
            fprintf(fid, '%s', strtrim(message));
            fclose(fid);
            fprintf('Client model saved in: %s\n',fname);
            ret = LINECLI('--file',fname,'--input','xml');
            conn.send(ret);
            conn.close();
        end
        
        function onBinaryMessage(obj,conn,bytearray)
            % This function sends an echo back to the client
            conn.send(bytearray); % Echo
        end
        
        function onError(obj,conn,message)
            fprintf('%s\n',message)
        end
        
        function onClose(obj,conn,message)
            fprintf('%s\n',message)
        end
    end
end

