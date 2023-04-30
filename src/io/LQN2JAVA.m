function LQN2JAVA(lqnmodel, modelName, fid)
% LQN2JAVA(MODEL, MODELNAME, FID)

% Copyright (c) 2012-2023, Imperial College London
% All rights reserved.

if nargin<2%~exist('modelName','var')
    modelName='myLayeredModel';
end
if nargin<3%~exist('fid','var')
    fid=1;
end
if ischar(fid)
    fid = fopen(fid,'w');
end
sn = lqnmodel.getStruct;

%% initialization
fprintf(fid,'package jline.examples;\n\n');
fprintf(fid,'import jline.lang.*;\n');
fprintf(fid,'import jline.lang.constant.*;\n');
fprintf(fid,'import jline.lang.distributions.*;\n');
fprintf(fid,'import jline.solvers.ln.SolverLN;\n\n');
fprintf(fid,'public class TestSolver%s {\n\n',upper(strrep(modelName,' ','')));
fprintf(fid,'\tpublic static void main(String[] args) throws Exception{\n\n');
fprintf(fid,'\tLayeredNetwork model = new LayeredNetwork("%s");\n',modelName);
fprintf(fid,'\n');
%% host processors
for h=1:sn.nhosts
    fprintf(fid, '\tProcessor P%d = new Processor(model, "%s", %d, %s);\n', h, sn.names{h}, sn.mult(h), strrep(SchedStrategy.toFeature(sn.sched{h}),'_','.'));
    if sn.repl(h)~=1
        fprintf(fid, 'P%d.setReplication(%d);\n', h, sn.repl(h));
    end
end
fprintf(fid,'\n');
%% tasks
for t=1:sn.ntasks
    tidx = sn.tshift+t;
    fprintf(fid, '\tTask T%d = new Task(model, "%s", %d, %s); T%d.on(P%d);\n', t, sn.names{tidx}, sn.mult(tidx), strrep(SchedStrategy.toFeature(sn.sched{tidx}),'_','.'), t,sn.parent(tidx));
    if sn.repl(tidx)~=1
        fprintf(fid, '\tT%d.setReplication(%d);\n', t, sn.repl(tidx));
    end
    if ~isempty(sn.think{tidx})
        switch sn.think{tidx}.name
            case 'Immediate'
                fprintf(fid, '\tT%d.setThinkTime(new Immediate());\n',t);
            case 'Exponential'
                fprintf(fid, '\tT%d.setThinkTime(new Exp(%g));\n',t, 1/sn.think{tidx}.getMean);
            case {'Erlang','HyperExp', 'Coxian', 'APH'}
                fprintf(fid, '\tT%d.setThinkTime(%s.fitMeanAndSCV(%g,%g));\n', t, sn.think{tidx}.name, sn.think{tidx}.getMean, sn.think{tidx}.getSCV);
            otherwise
                line_error(mfilename,sprintf('LQN2SCRIPT does not support the %d distribution yet.',sn.think{tidx}.name));
        end
    end
end
    fprintf(fid,'\n');
%% entries
for e=1:sn.nentries
    eidx = sn.eshift+e;
    fprintf(fid, '\tEntry E%d = new Entry(model, "%s"); E%d.on(T%d);\n', e, sn.names{eidx},e,sn.parent(eidx)-sn.tshift);
end
fprintf(fid,'\n');
%% activities
for a=1:sn.nacts
    aidx = sn.ashift+a;
    tidx = sn.parent(aidx);
    onTask = tidx-sn.tshift;
    boundTo = find(sn.graph((sn.eshift+1):(sn.eshift+sn.nentries),aidx));
    boundToStr = '';
    if ~isempty(boundTo)
        boundToStr = sprintf('.boundTo(E%d)',boundTo);
    end
    if sn.sched{tidx} ~= SchedStrategy.ID_REF % ref tasks don't reply
        repliesToStr = '';
        repliesTo = find(sn.replygraph(aidx,:))-sn.eshift; % index of entry
        if ~isempty(repliesTo)
            if ~sn.isref(sn.parent(sn.eshift+repliesTo))
                repliesToStr = sprintf('.repliesTo(E%d)',repliesTo);
            end
        end
    end    
    callStr = '';
    if ~isempty(sn.callpair)
        cidxs = find(sn.callpair(:,1)==aidx);
        calls = sn.callpair(:,2);
        for c=cidxs(:)'
            switch sn.calltype(c)
                case CallType.ID_SYNC
                    callStr = sprintf('%s.synchCall(E%d,%g)',callStr,calls(c)-sn.eshift,sn.callproc{c}.getMean);
                case CallType.ID_ASYNC
                    callStr = sprintf('%s.asynchCall(E%d,%g)',callStr,calls(c)-sn.eshift,sn.callproc{c}.getMean);
            end
        end
    end
    switch sn.hostdem{aidx}.name
        case 'Immediate'
            fprintf(fid, '\tActivity A%d = new Activity(model, "%s", new Immediate()); A%d.on(T%d);', a, sn.names{aidx}, a, onTask);
        case 'Exponential'
            fprintf(fid, '\tActivity A%d = new Activity(model, "%s", new Exp(%g)); A%d.on(T%d);', a, sn.names{aidx},1/sn.hostdem{aidx}.getMean, a, onTask);
        case {'Erlang','HyperExp','Coxian','APH'}
            fprintf(fid, '\tActivity A%d = new Activity(model, "%s", new %s.fitMeanAndSCV(%g,%g)); A%d.on(T%d);', a, sn.names{aidx},sn.hostdem{aidx}.name,sn.hostdem{aidx}.getMean,sn.hostdem{aidx}.getSCV, a, onTask);
        otherwise
            line_error(mfilename,sprintf('LQN2SCRIPT does not support the %d distribution yet.',sn.hostdem{aidx}.name));
    end
    if ~isempty(boundToStr)
        fprintf(fid, ' A%d%s;', a, boundToStr);
    end
    if ~isempty(callStr)
        fprintf(fid, ' A%d%s;', a, callStr);
    end
    if ~isempty(repliesToStr)
        fprintf(fid, ' A%d%s;', a, repliesToStr);
    end
    fprintf(fid,'\n');   
end
fprintf(fid,'\n');
%% think times
for h=1:sn.nhosts
    if ~isempty(sn.think{h})
        switch sn.think{h}.name
            case 'Immediate'
                fprintf(fid, '\tP%d.setThinkTime(Immediate());\n', h);
            case 'Exponential'
                fprintf(fid, '\tP%d.setThinkTime(Exp(%g));\n', h, sn.think{h}.getMean);
            case {'Erlang','HyperExp','Coxian','APH'}
                fprintf(fid, '\tP%d.setThinkTime(%s.fitMeanAndSCV(%g,%g));\n', h, sn.think{h}.name, sn.think{h}.getMean, sn.think{h}.getSCV);
            otherwise
                line_error(mfilename,sprintf('LQN2SCRIPT does not support the %d distribution yet.',sn.think{h}.name));
        end
    end
end

%% Sequential precedences
for ai = 1:sn.nacts
    aidx = sn.ashift + ai;
    tidx = sn.parent(aidx);
    % for all successors
    for bidx=find(sn.graph(aidx,:))
        if bidx > sn.ashift % ignore precedence between entries and activities
            % Serial pattern (SEQ)
            if full(sn.actpretype(aidx)) == ActivityPrecedenceType.ID_PRE_SEQ && full(sn.actposttype(bidx)) == ActivityPrecedenceType.ID_POST_SEQ
                fprintf(fid, '\tT%d.addPrecedence(ActivityPrecedence.Sequence("%s", "%s"));\n', tidx-sn.tshift, sn.names{aidx}, sn.names{bidx});
            end
        end
    end
end

%% Loop precedences (POST_LOOP)
precMarker = 0;
for ai = 1:sn.nacts
    aidx = sn.ashift + ai;
    tidx = sn.parent(aidx);
    % for all successors
    for bidx=find(sn.graph(aidx,:))
        if bidx > sn.ashift % ignore precedence between entries and activities
            % Loop pattern (POST_LOOP)
            if full(sn.actposttype(bidx)) == ActivityPrecedenceType.ID_POST_LOOP
                if precMarker == 0 % start a new loop
                    precMarker = aidx-sn.ashift;
                    precActs = '';
                else
                    if isempty(precActs)
                        precActs = sprintf('A%d', bidx-sn.ashift);
                    else
                        precActs = sprintf('%s, A%d',precActs, bidx-sn.ashift);
                    end
                    if aidx ~= bidx % loop end reached
                        counts = 1/sn.graph(aidx,bidx);
                        fprintf(fid, '\tT%d.addPrecedence(ActivityPrecedence.Loop(A%d, {%s}, %g));\n', tidx-sn.tshift, precMarker, precActs, counts);
                        precMarker = 0;
                    end
                end
            end
        end
    end
end

%% OrFork precedences (POST_OR)
precMarker = 0;
for ai = 1:sn.nacts
    aidx = sn.ashift + ai;
    tidx = sn.parent(aidx);
    % for all successors
    for bidx=find(sn.graph(aidx,:))
        if bidx > sn.ashift % ignore precedence between entries and activities
            % Or pattern (POST_OR)
            if full(sn.actposttype(bidx)) == ActivityPrecedenceType.ID_POST_OR
                if precMarker == 0 % start a new orjoin
                    precMarker = aidx-sn.ashift;
                    precActs = sprintf('A%d', bidx-sn.ashift);
                    probs = sprintf('%g',full(sn.graph(aidx,bidx)));
                else
                    precActs = sprintf('%s, A%d', precActs, bidx-sn.ashift);
                    probs = sprintf('%s,%g',probs,full(sn.graph(aidx,bidx)));
                end
            end
        end
    end    
    if precMarker > 0
        fprintf(fid, '\tT%d.addPrecedence(ActivityPrecedence.OrFork(A%d,{%s},[%s]));\n', tidx-sn.tshift, precMarker, precActs, probs);
        precMarker = 0;
    end
end

%% AndFork precedences (POST_AND)
precMarker = 0;
for ai = 1:sn.nacts
    aidx = sn.ashift + ai;
    tidx = sn.parent(aidx);
    % for all successors
    for bidx=find(sn.graph(aidx,:))
        if bidx > sn.ashift % ignore precedence between entries and activities
            % Or pattern (POST_AND)
            if full(sn.actposttype(bidx)) == ActivityPrecedenceType.ID_POST_AND
                if precMarker == 0 % start a new orjoin
                    precMarker = aidx-sn.ashift;
                    precActs = sprintf('A%d', bidx-sn.ashift);
                else
                    precActs = sprintf('%s, A%d', precActs, bidx-sn.ashift);
                end
            end
        end
    end    
    if precMarker > 0
        fprintf(fid, '\tT%d.addPrecedence(ActivityPrecedence.AndFork(A%d,{%s}));\n', tidx-sn.tshift, precMarker, precActs);
        precMarker = 0;
    end
end


%% OrJoin precedences (PRE_OR)
precMarker = 0;
for bi = sn.nacts:-1:1
    bidx = sn.ashift + bi;
    tidx = sn.parent(bidx);
    % for all predecessors
    for aidx=find(sn.graph(:,bidx))'
        if aidx > sn.ashift % ignore precedence between entries and activities
            % OrJoin pattern (PRE_OR)
            if full(sn.actpretype(aidx)) == ActivityPrecedenceType.ID_PRE_OR
                if precMarker == 0 % start a new orjoin
                    precMarker = bidx-sn.ashift;
                    precActs = sprintf('A%d', aidx-sn.ashift);
                else
                    precActs = sprintf('%s, A%d',precActs, aidx-sn.ashift);
                end
            end
        end
    end    
    if precMarker > 0
        fprintf(fid, '\tT%d.addPrecedence(ActivityPrecedence.OrJoin({%s}, A%d));\n', tidx-sn.tshift, precActs, precMarker);
        precMarker = 0;
    end
end

%% OrJoin precedences (PRE_AND)
precMarker = 0;
for bi = sn.nacts:-1:1
    bidx = sn.ashift + bi;
    tidx = sn.parent(bidx);
    % for all predecessors
    for aidx=find(sn.graph(:,bidx))'
        if aidx > sn.ashift % ignore precedence between entries and activities
            % OrJoin pattern (PRE_AND)
            if full(sn.actpretype(aidx)) == ActivityPrecedenceType.ID_PRE_AND
                if precMarker == 0 % start a new orjoin
                    precMarker = bidx-sn.ashift;
                    precActs = sprintf('A%d', aidx-sn.ashift);
                else
                    precActs = sprintf('%s, A%d',precActs, aidx-sn.ashift);
                end
            end
        end
    end    
    if precMarker > 0
        fprintf(fid, '\tT%d.addPrecedence(ActivityPrecedence.AndJoin({%s}, A%d));\n', tidx-sn.tshift, precActs, precMarker);
        precMarker = 0;
    end
end


fprintf(fid,'\tSolverLN solver = new SolverLN(model);\n');
fprintf(fid,'\tsolver.getEnsembleAvg();\n');
fprintf(fid,'\t}\n}\n');

if ischar(fid)
    fclose(fid);
end
end
