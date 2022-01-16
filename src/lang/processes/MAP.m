classdef MAP < MarkovModulated
    % Markovian Arrival Process
    %
    % Copyright (c) 2012-2022, Imperial College London
    % All rights reserved.

    methods
        %Constructor
        function self = MAP(D0,D1)
            % SELF = MAP(D0,D1)

            self@MarkovModulated('MAP',2);
            if nargin < 2 && iscell(D0)
                M = D0;
                D0 = M{1};
                D1 = M{2};
            end
            setParam(self, 1, 'D0', D0, 'java.lang.Double');
            setParam(self, 2, 'D1', D1, 'java.lang.Double');
        end

        function meant = getMeanT(self,t)
            % MEANT = GETMEANT(SELF,T)
            D0 =  self.getParam(1).paramValue;
            D1 =  self.getParam(2).paramValue;
            lambda = map_lambda({D0,D1});
            meant = lambda * t;
        end

        function vart = evalVarT(self,t)
            % VART = EVALVART(SELF,T)

            % Evaluate the variance-time curve at t
            D0 =  self.getParam(1).paramValue;
            D1 =  self.getParam(2).paramValue;
            vart =  map_count_var({D0,D1},t);
        end

        % inter-arrival time properties
        function mean = getMean(self)
            % MEAN = GETMEAN()

            D0 =  self.getParam(1).paramValue;
            D1 =  self.getParam(2).paramValue;
            mean = map_mean({D0,D1});
        end

        function scv = getSCV(self)
            % SCV = GETSCV()

            D0 =  self.getParam(1).paramValue;
            D1 =  self.getParam(2).paramValue;
            scv = map_scv({D0,D1});
        end

        function id = getID(self) % asymptotic index of dispersion
            % ID = GETID() % ASYMPTOTIC INDEX OF DISPERSION

            D0 =  self.getParam(1).paramValue;
            D1 =  self.getParam(2).paramValue;
            id = map_idc({D0,D1});
        end

        function MAP = getRepresentation(self)
            % MAP = GETREPRESENTATION()
            MAP = getProcess(self);
        end

        function lam = getRate(self)
            % MAP = GETRATE()

            D0 =  self.getParam(1).paramValue;
            D1 =  self.getParam(2).paramValue;
            lam = map_lambda({D0,D1});
        end

        function MAP = getProcess(self)
            % MAP = GETPROCESS()

            D0 =  self.getParam(1).paramValue;
            D1 =  self.getParam(2).paramValue;
            MAP = {D0,D1};
        end

        function n = getNumberOfPhases(self)
            % N = GETNUMBEROFMAPASES()
            D0 =  self.getParam(1).paramValue;
            n = length(D0);
        end

        function mu = getMu(self)
            % MU = GETMU()
            % Aggregate departure rate from each state
            MAP = getProcess(self);
            mu = sum(MAP{2},2); % sum D1 rows / diag -D0
        end

        function phi = getPhi(self)
            % MAPI = GETMAPI()
            % Return the exit vector of the underlying MAP
            MAP = getProcess(self);
            phi = sum(MAP{2},2) ./ diag(-MAP{1}); % sum D1 rows / diag -D0
        end

        function bool = isImmmediate(self)
            % BOOL = ISIMMMEDIATE()

            bool = getMean(self) == 0;
        end
    end

    methods (Static)
        function [MAP, logL] = emfit(trace, order, iter_max, iter_tol, verbose)
            % MAP = EMFIT(TRACE, ORDERS)

            % MAP = EMFIT(TRACE, ORDERS, ITER_MAX, ITER_TOL, VERBOSE)
            %
            % X = MAP.emfit(S, 4) % attempt all possible ER-CHMM structures in a MAP(4)
            % X = MAP.emfit(S, [1,3]) % attemp a ER-CHMM structure with an exponential and an Erlang-3

            if nargin< 3
                iter_max = 100;
            end

            if nargin< 4
                iter_tol = 1e-7; % stop condition on the iterations
            end

            if nargin< 5
                verbose = true;
            end

            [MAP, logL] = erchmm_emfit(trace, order, iter_max, iter_tol, verbose);
        end
    end
end
