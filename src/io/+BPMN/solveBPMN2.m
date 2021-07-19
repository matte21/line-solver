function solveBPMN(filename, extFilename, verbose)
% SOLVEBPMN solves a BPMN model specified by the BPMN XML file FILENAME 
% and the XML extension file EXTFILENAME. The extended BPMN model is 
% transformed into an LQN model, solvedm and the results are saved in 
% XML format in the same folder as the input file, and with the same 
% name adding the suffix '-line.xml' 
% 
% Input:
% filename:             filepath of the BPMN XML file with the model to solve
% extFilename:          filepath of the XML extension file for the model to solve 
% options.outputFolder: path of an alternative output folder
% options.RTdist:       1 if the response-time distribution is to be
%                       computed, 0 otherwise
% options.RTrange:      array of double in (0,1) with the percentiles to 
%                       evaluate the response-time distribution
% options.verbose:      1 for screen output, 0 otherwise  
%    
% Copyright (c) 2012-2016, Imperial College London 
% All rights reserved.

%import BPMN.*;

if nargin < 3 
    options = [];
end

%% input files parsing
model = BPMN.parseXML_BPMN(filename, verbose);
modelExt = BPMN.parseXML_BPMNextensions(extFilename, verbose);

if ~isempty(model) && ~isempty(modelExt)
    %% create lqn model from bpmn  
    myLQN = BPMN.BPMN2LQN(model, modelExt, verbose); 
    
    %% obtain line performance model from lqn
    options = SolverLQNS.defaultOptions;
    options.keep = true; % uncomment to keep the intermediate XML files generates while translating the model to LQNS

    solver{1} = SolverLQNS(myLQN);
    AvgTable{1} = solver{1}.getAvgTable();
    AvgTable{1}

    useLQNSnaming = true;
    AvgTable{2} = solver{1}.getAvgTable(useLQNSnaming);
    AvgTable{2}


    useLQNSnaming = true;
    [AvgTable{3}, CallAvgTable{3}] = solver{1}.getRawAvgTables();
    AvgTable{3}
    CallAvgTable{3}
end
end
