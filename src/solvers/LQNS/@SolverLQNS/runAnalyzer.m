function runtime = runAnalyzer(self, options)
% RUNTIME = RUN()
% Run the solver

tic;
options = self.getOptions;
dirpath = lineTempName('lqns');
filename = [dirpath,filesep,'model.lqnx'];
self.model.writeXML(filename);

if options.verbose
    verbose = '-v';
else
    verbose = '-w';
end

multiserver_praqma = '';
switch options.config.multiserver
    case 'conway'
        multiserver_praqma='-Pmultiserver=conway';
    case 'rolia'
        multiserver_praqma='-Pmultiserver=rolia';
    case 'zhou'
        multiserver_praqma='-Pmultiserver=zhou';
    case 'suri'
        multiserver_praqma='-Pmultiserver=suri';
    case 'reiser'
        multiserver_praqma='-Pmultiserver=reiser';
    case 'schmidt'
        multiserver_praqma='-Pmultiserver=schmidt';
    case 'default'
        multiserver_praqma='-Pmultiserver=rolia';
end

if isunix
    %                 switch options.method
    %                     case {'default','lqns'}
    %                         system(['lqns ',verbose,' ',multiserver_praqma,' --iteration-limit=',num2str(options.iter_max),' -Pstop-on-message-loss=false -x ',filename]);
    %                     case {'srvn'}
    %                         system(['lqns ',verbose,' ',multiserver_praqma,' --iteration-limit=',num2str(options.iter_max),' -Playering=srvn -Pstop-on-message-loss=false -x ',filename]);
    %                     case {'exactmva'}
    %                         system(['lqns ',verbose,' ',multiserver_praqma,' --iteration-limit=',num2str(options.iter_max),' -Pmva=exact -Pstop-on-message-loss=false -x ',filename]);
    %                     case {'srvnexact'}
    %                         system(['lqns ',verbose,' ',multiserver_praqma,' --iteration-limit=',num2str(options.iter_max),' -Playering=srvn -Pmva=exact -Pstop-on-message-loss=false -x ',filename]);
    %                     case {'sim','lqsim'}
    %                         system(['lqsim ',verbose,' ',multiserver_praqma,' -A ',num2str(options.samples),',3  -Pstop-on-message-loss=false -x ',filename]);
    %                     case {'lqnsdefault'}
    %                         system(['lqns ',verbose,' ',multiserver_praqma,' -x ',filename]);
    %                     otherwise
    %                         system(['lqns ',verbose,' ',multiserver_praqma,' --iteration-limit=',num2str(options.iter_max),' -Pstop-on-message-loss=false -x ',filename]);
    %                 end

    % --iteration-limit seems faulty as of 6.2.27
    if options.verbose
        switch options.method
            case {'default','lqns'}
                system(['lqns ',verbose,' ',multiserver_praqma,' -Pstop-on-message-loss=false -x ',filename]);
            case {'srvn'}
                system(['lqns ',verbose,' ',multiserver_praqma,' -Playering=srvn -Pstop-on-message-loss=false -x ',filename]);
            case {'exactmva'}
                system(['lqns ',verbose,' ',multiserver_praqma,' -Pmva=exact -Pstop-on-message-loss=false -x ',filename]);
            case {'srvn.exactmva'}
                system(['lqns ',verbose,' ',multiserver_praqma,' -Playering=srvn -Pmva=exact -Pstop-on-message-loss=false -x ',filename]);
            case {'sim','lqsim'}
                system(['lqsim ',verbose,' ',multiserver_praqma,' -A ',num2str(options.samples),',3  -Pstop-on-message-loss=false -x ',filename]);
            case {'lqnsdefault'}
                system(['lqns ',verbose,' ',multiserver_praqma,' -x ',filename]);
            otherwise
                system(['lqns ',verbose,' ',multiserver_praqma,' -Pstop-on-message-loss=false -x ',filename]);
        end
    else
        switch options.method
            case {'default','lqns'}
                system(['lqns ',verbose,' ',multiserver_praqma,' -Pstop-on-message-loss=false -x ',filename,' 2>&1']);
            case {'srvn'}
                system(['lqns ',verbose,' ',multiserver_praqma,' -Playering=srvn -Pstop-on-message-loss=false -x ',filename,' 2>&1']);
            case {'exactmva'}
                system(['lqns ',verbose,' ',multiserver_praqma,' -Pmva=exact -Pstop-on-message-loss=false -x ',filename,' 2>&1']);
            case {'srvn.exactmva'}
                system(['lqns ',verbose,' ',multiserver_praqma,' -Playering=srvn -Pmva=exact -Pstop-on-message-loss=false -x ',filename,' 2>&1']);
            case {'sim','lqsim'}
                system(['lqsim ',verbose,' ',multiserver_praqma,' -A ',num2str(options.samples),',3  -Pstop-on-message-loss=false -x ',filename,' 2>&1']);
            case {'lqnsdefault'}
                system(['lqns ',verbose,' ',multiserver_praqma,' -x ',filename,' 2>&1']);
            otherwise
                system(['lqns ',verbose,' ',multiserver_praqma,' -Pstop-on-message-loss=false -x ',filename,' 2>&1']);
        end
    end
else
    switch options.method
%         case {'default','lqns'}
%             system(['lqns ',verbose,' ',multiserver_praqma,' -i ',num2str(options.iter_max),' -Pstop-on-message-loss=false -x ',filename]);
%         case {'srvn'}
%             system(['lqns ',verbose,' ',multiserver_praqma,' -i ',num2str(options.iter_max),' -Playering=srvn -Pstop-on-message-loss=false -x ',filename]);
%         case {'exactmva'}
%             system(['lqns ',verbose,' ',multiserver_praqma,' -i ',num2str(options.iter_max),' -Pmva=exact -Pstop-on-message-loss=false -x ',filename]);
%         case {'srvnexact'}
%             system(['lqns ',verbose,' ',multiserver_praqma,' -i ',num2str(options.iter_max),' -Playering=srvn -Pmva=exact -Pstop-on-message-loss=false -x ',filename]);
%         case {'sim','lqsim'}
%             system(['lqsim ',verbose,' ',multiserver_praqma,' -A ',num2str(options.samples),',3  -Pstop-on-message-loss=false -x ',filename]);
%         case {'lqnsdefault'}
%             system(['lqns ',verbose,' ',multiserver_praqma,' -x ',filename]);
%         otherwise
%             system(['lqns ',verbose,' ',multiserver_praqma,' -i ',num2str(options.iter_max),' -Pstop-on-message-loss=false -x ',filename]);
        case {'default','lqns'}
            system(['lqns ',verbose,' ',multiserver_praqma,' -Pstop-on-message-loss=false -x ',filename]);
        case {'srvn'}
            system(['lqns ',verbose,' ',multiserver_praqma,' -Playering=srvn -Pstop-on-message-loss=false -x ',filename]);
        case {'exactmva'}
            system(['lqns ',verbose,' ',multiserver_praqma,' -Pmva=exact -Pstop-on-message-loss=false -x ',filename]);
        case {'srvn.exactmva'}
            system(['lqns ',verbose,' ',multiserver_praqma,' -Playering=srvn -Pmva=exact -Pstop-on-message-loss=false -x ',filename]);
        case {'sim','lqsim'}
            system(['lqsim ',verbose,' ',multiserver_praqma,' -A ',num2str(options.samples),',3  -Pstop-on-message-loss=false -x ',filename]);
        case {'lqnsdefault'}
            system(['lqns ',verbose,' ',multiserver_praqma,' -x ',filename]);
        otherwise
            system(['lqns ',verbose,' ',multiserver_praqma,' -Pstop-on-message-loss=false -x ',filename]);
    end
end

self.parseXMLResults(filename);

if ~options.keep
    rmdir(dirpath,'s');
end
runtime = toc;
end
