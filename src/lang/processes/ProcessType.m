classdef (Sealed) ProcessType
    % Enumeration of process types
    %
    % Copyright (c) 2012-2021, Imperial College London
    % All rights reserved.
    
    properties (Constant)
        EXP = 'exp'; % renewal
        ERLANG = 'erlang';% renewal
        HYPEREXP = 'hyperexp';% renewal
        PH = 'ph'; % renewal
        APH = 'aph';% renewal
        MAP = 'map';% renewal
        UNIFORM = 'uniform';% renewal
        DET = 'det';% renewal
        COXIAN = 'coxian';% renewal
        GAMMA = 'gamma';% renewal
        PARETO = 'pareto';% renewal
        MMPP2 = 'mmpp2';
        REPLAYER = 'trace';
        TRACE = 'trace';
        IMMEDIATE = 'immediate';
        DISABLED = 'disabled';
        COX2 = 'cox2';
        
        ID_EXP = 0;
        ID_ERLANG = 1;
        ID_HYPEREXP = 2;
        ID_PH = 3;
        ID_APH = 4;
        ID_MAP = 5;
        ID_UNIFORM = 6;
        ID_DET = 7;
        ID_COXIAN = 8;
        ID_GAMMA = 9;
        ID_PARETO = 10;
        ID_MMPP2 = 11;
        ID_REPLAYER = 12;
        ID_TRACE = 12;
        ID_IMMEDIATE = 13;
        ID_DISABLED = 14;
        ID_COX2 = 15;
    end
    
    methods (Static)
        
        function type = fromId(id)
            % ID = TOID(TYPE)
            switch id
                case 0
                    type = ProcessType.EXP;;
                case 1
                    type = ProcessType.ERLANG;
                case 2
                    type = ProcessType.HYPEREXP;
                case 3
                    type = ProcessType.PH;
                case 4
                    type = ProcessType.APH;
                case 5
                    type = ProcessType.MAP;
                case 6
                    type = ProcessType.UNIFORM;
                case 7
                    type = ProcessType.DET;
                case 8
                    type = ProcessType.COXIAN;
                case 9
                    type = ProcessType.GAMMA;
                case 10
                    type = ProcessType.PARETO;
                case 11
                    type = ProcessType.MMPP2;
                case 12
                    type = ProcessType.TRACE;
                case 13
                    type = ProcessType.IMMEDIATE;
                case 14
                    type = ProcessType.DISABLED;
            end
        end
        function id = toId(type)
            % ID = TOID(TYPE)
            switch type
                case ProcessType.EXP
                    id = 0;
                case ProcessType.ERLANG
                    id = 1;
                case ProcessType.HYPEREXP
                    id = 2;
                case ProcessType.PH
                    id = 3;
                case ProcessType.APH
                    id = 4;
                case ProcessType.MAP
                    id = 5;
                case ProcessType.UNIFORM
                    id = 6;
                case ProcessType.DET
                    id = 7;
                case ProcessType.COXIAN
                    id = 8;
                case ProcessType.GAMMA
                    id = 9;
                case ProcessType.PARETO
                    id = 10;
                case ProcessType.MMPP2
                    id = 11;
                case {ProcessType.REPLAYER, ProcessType.TRACE}
                    id = 12;
                case ProcessType.IMMEDIATE
                    id = 13;
                case ProcessType.DISABLED
                    id = 14;
            end
        end
        
        function type = fromText(text)
            % TIMMEDIATE = TOID(TYPE)
            switch text
                case 'Exp'
                    type = ProcessType.EXP;
                case 'Erlang'
                    type = ProcessType.ERLANG;
                case 'HyperExp'
                    type = ProcessType.HYPEREXP;
                case 'PH'
                    type = ProcessType.PH;
                case 'APH'
                    type = ProcessType.APH;
                case 'MAP'
                    type = ProcessType.MAP;
                case 'Uniform'
                    type = ProcessType.UNIFORM;
                case 'Det'
                    type = ProcessType.DET;
                case 'Coxian'
                    type = ProcessType.COXIAN;
                case 'Gamma'
                    type = ProcessType.GAMMA;
                case 'Pareto'
                    type = ProcessType.PARETO;
                case 'MMPP2'
                    type = ProcessType.MMPP2;
                case 'Replayer'
                    type = ProcessType.TRACE;
                case 'Immediate'
                    type = ProcessType.IMMEDIATE;
                case 'Disabled'
                    type = ProcessType.DISABLED;
                case 'Cox2'
                    type = ProcessType.COX2;
            end
        end
        
        function text = toText(type)
            % TEXT = TOTEXT(TYPE)
            switch type
                case ProcessType.EXP
                    text = 'Exp';
                case ProcessType.ERLANG
                    text = 'Erlang';
                case ProcessType.HYPEREXP
                    text = 'HyperExp';
                case ProcessType.PH
                    text = 'PH';
                case ProcessType.APH
                    text = 'APH';
                case ProcessType.MAP
                    text = 'MAP';
                case ProcessType.UNIFORM
                    text = 'Uniform';
                case ProcessType.DET
                    text = 'Det';
                case ProcessType.COXIAN
                    text = 'Coxian';
                case ProcessType.GAMMA
                    text = 'Gamma';
                case ProcessType.PARETO
                    text = 'Pareto';
                case ProcessType.MMPP2
                    text = 'MMPP2';
                case {ProcessType.REPLAYER, ProcessType.TRACE}
                    text = 'Replayer';
                case ProcessType.IMMEDIATE
                    text = 'Immediate';
                case ProcessType.DISABLED
                    text = 'Disabled';
                case ProcessType.COX2
                    text = 'Cox2';
            end
            
        end
        
    end
end
