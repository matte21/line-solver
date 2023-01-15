classdef ActivityPrecedence
    % An auxiliary class to specify precedence among Activity elements.
    %
    % Copyright (c) 2012-2023, Imperial College London
    % All rights reserved.

    properties
        preActs;        %string array
        postActs;       %string array
        preType;        %string
        postType;       %string
        preParams;      %double array
        postParams;     %double array
    end

    methods
        %public methods, including constructor

        %constructor
        function obj = ActivityPrecedence(preActs, postActs, preType, postType, preParams, postParams)
            % OBJ = ACTIVITYPRECEDENCE(PREACTS, POSTACTS, PRETYPE, POSTTYPE, PREPARAMS, POSTPARAMS)

            if nargin<2 %~exist('preActs','var') || ~exist('postActs','var')
                line_error(mfilename,'Constructor requires to specify at least pre and post activities.');
            end

            if nargin<3 %~exist('preType','var')
                preType = ActivityPrecedenceType.PRE_SEQ;
            end
            if nargin<4 %~exist('postType','var')
                postType = ActivityPrecedenceType.POST_SEQ;
            end
            if nargin<5 %~exist('preParams','var')
                preParams = [];
            end
            if nargin<6 %~exist('postParams','var')
                postParams = [];
            end
            for a=1:length(preActs)
                if isa(preActs{a},'Activity')
                   preActs{a} = preActs{a}.getName;
                end
            end
            obj.preActs = preActs;
            for a=1:length(postActs)
                if isa(postActs{a},'Activity')
                    postActs{a} = postActs{a}.getName;
                end
            end
            obj.postActs = postActs;
            obj.preType = preType;
            obj.postType = postType;
            obj.preParams = preParams;
            obj.postParams = postParams;
        end

    end

    methods (Static, Hidden)
         function ap = Sequence(preAct, postAct)
            % AP = SEQUENCE(PREACT, POSTACT)
	    %
            % Auxiliary method, use Serial instead.

            if isa(preAct,'Activity')
                preAct = preAct.name;
            end
            if isa(postAct,'Activity')
                postAct = postAct.name;
            end
            ap = ActivityPrecedence({preAct},{postAct});
        end
    end 

    methods (Static)
         function ap = Serial(varargin)
            % AP = SERIAL(VARARGIN)

            ap = cell(nargin-1,1);
            for m = 1:nargin-1
                ap{m} = ActivityPrecedence.Sequence(varargin{m},varargin{m+1});
            end
       end

       function ap = AndJoin(preActs, postAct, quorum)
            % AP = ANDJOIN(PREACTS, POSTACT, QUORUM)

            for a = 1:length(preActs)
                if isa(preActs{a},'Activity')
                    preActs{a} = preActs{a}.name;
                end
            end
            if isa(postAct,'Activity')
                postAct = postAct.name;
            end
            if nargin<3 %~exist('quorum','var')
                quorum = [];
            end
            ap = ActivityPrecedence(preActs,{postAct},ActivityPrecedenceType.PRE_AND,ActivityPrecedenceType.POST_SEQ,quorum,[]);
        end

        function ap = OrJoin(preActs, postAct)
            % AP = ORJOIN(PREACTS, POSTACT)

            for a = 1:length(preActs)
                if isa(preActs{a},'Activity')
                    preActs{a} = preActs{a}.name;
                end
            end
            if isa(postAct,'Activity')
                postAct = postAct.name;
            end
            ap = ActivityPrecedence(preActs,{postAct},ActivityPrecedenceType.PRE_OR,ActivityPrecedenceType.POST_SEQ);
        end

        function ap = AndFork(preAct, postActs)
            % AP = ANDFORK(PREACT, POSTACTS)

            if isa(preAct,'Activity')
                preAct = preAct.name;
            end
            for a = 1:length(postActs)
                if isa(postActs{a},'Activity')
                    postActs{a} = postActs{a}.name;
                end
            end
            ap = ActivityPrecedence({preAct},postActs,ActivityPrecedenceType.PRE_SEQ,ActivityPrecedenceType.POST_AND);
        end

        function ap = Xor(preAct, postActs, probs)
            % AP = XOR(PREACT, POSTACTS, PROBS)
            %
            % This is a pseudonym for OrFork
            ap = ActivityPrecedence.OrFork(preAct, postActs, probs);
        end

        function ap = OrFork(preAct, postActs, probs)
            % AP = ORFORK(PREACT, POSTACTS, PROBS)
            %
            % OrFork is the terminology used in LQNs for a probabilistic
            % or, where a call chooses a branch with given probability

            if isa(preAct,'Activity')
                preAct = preAct.name;
            end
            for a = 1:length(postActs)
                if isa(postActs{a},'Activity')
                    postActs{a} = postActs{a}.name;
                end
            end
            ap = ActivityPrecedence({preAct},postActs,ActivityPrecedenceType.PRE_SEQ,ActivityPrecedenceType.POST_OR,[],probs);
        end

        function ap = Loop(preAct, postActs, counts)
            % AP = LOOP(PREACT, POSTACTS, COUNTS)

            if isa(preAct,'Activity')
                preAct = preAct.name;
            end
            for a = 1:length(postActs)
                if isa(postActs{a},'Activity')
                    postActs{a} = postActs{a}.name;
                end
            end
            ap = ActivityPrecedence({preAct},postActs,ActivityPrecedenceType.PRE_SEQ,ActivityPrecedenceType.POST_LOOP,[],counts);
        end

        function ap = CacheAccess(preAct, postActs)
            % AP = ORFORK(PREACT, POSTACTS, PROBS)

            if isa(preAct,'Activity')
                preAct = preAct.name;
            end
            for a = 1:length(postActs)
                if isa(postActs{a},'Activity')
                    postActs{a} = postActs{a}.name;
                end
            end
            ap = ActivityPrecedence({preAct},postActs,ActivityPrecedenceType.PRE_SEQ,ActivityPrecedenceType.POST_CACHE);
        end
    end

end
