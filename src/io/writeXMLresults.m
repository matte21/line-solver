function writeXMLresults(filenameLQN, filenameRE, qn, util, XN, RT, RN, resEntries, RT_CDF,resEntries_CDF, verbose)
% Copyright (c) 2012-2019, Imperial College London
% All rights reserved.


import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.DocumentBuilder;
import org.w3c.dom.Document;
import org.w3c.dom.NodeList;
import org.w3c.dom.Node;
import org.w3c.dom.Element;
import java.io.File;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.dom.DOMSource; 
import javax.xml.transform.stream.StreamResult; 
import javax.xml.transform.OutputKeys;

precision = '%10.15e'; %precision for doubles
%DocumentBuilderFactory 
docFactory = DocumentBuilderFactory.newInstance();
%DocumentBuilder 
docBuilder = docFactory.newDocumentBuilder();
%Document 
doc = docBuilder.newDocument();

%Root Element 
rootElement = doc.createElement('cqn-model');
doc.appendChild(rootElement);
rootElement.setAttribute('xmlns:xsi', 'http://www.w3.org/2001/XMLSchema-instance');

rootElement.setAttribute('name', 'CQNmodel');


for j = 1:qn.nstations
    %processor
    procElement = doc.createElement('processor');
    rootElement.appendChild(procElement);
    procElement.setAttribute('name', qn.stationnames{j});
    if nargin > 2 && ~isempty(util)
        procElement.setAttribute('util', num2str(util(j), precision));
    end
end

origK = qn.nchains; % number of chains

for k = 1:origK
    %processor
    workElement = doc.createElement('workload');
    rootElement.appendChild(workElement);
    workElement.setAttribute('name', qn.classnames{k});
    %throughput
    if nargin > 3 && ~isempty(XN)
        workElement.setAttribute('throughput', num2str(XN(k), precision));
    end
    % overall mean response time
    if nargin > 4 && ~isempty(RT)
        workElement.setAttribute('responseTime', num2str(RT(k), precision));
    end
    % mean response time in each station
    if nargin > 5 && ~isempty(RN)
        for j = 1:qn.nstations
            statElement = doc.createElement('station');
            workElement.appendChild(statElement);
            statElement.setAttribute('name', qn.stationnames{j});
            statElement.setAttribute('responseTime', num2str(RN(j,k), precision));
        end
    end
    % overall response time percentiles
    if nargin > 9 && ~isempty(RT_CDF)
        rtElement = doc.createElement('responseTimeDistribution');
        workElement.appendChild(rtElement);
        for i = 1:size(RT_CDF{k,1},1)
            if ~isempty(RT_CDF{k,1}(i))
                percElement = doc.createElement('percentile');
                rtElement.appendChild(percElement); 
                percElement.setAttribute('level', num2str(RT_CDF{k,2}(i), precision));
                percElement.setAttribute('value', num2str(RT_CDF{k,1}(i), precision));
            end
        end
        
    end
    
end

for j = 1:size(resEntries,1)
    %Entries
    entryElement = doc.createElement('Entry');
    rootElement.appendChild(entryElement);
    entryElement.setAttribute('name', resEntries{j,1});
    entryElement.setAttribute('responseTime', num2str( resEntries{j,2}, precision));
    entryElement.setAttribute('throughput', num2str( resEntries{j,3}, precision));
    % Entries response time percentiles
    if nargin > 10 && ~isempty(resEntries_CDF)
        rtElement = doc.createElement('responseTimeDistribution');
        entryElement.appendChild(rtElement);
        for i = 1:size(resEntries_CDF{j,1},1)
            if ~isempty(resEntries_CDF{j,1}(i))
                percElement = doc.createElement('percentile');
                rtElement.appendChild(percElement); 
                percElement.setAttribute('level', num2str(resEntries_CDF{j,2}(i), precision));
                percElement.setAttribute('value', num2str(resEntries_CDF{j,1}(i), precision));
            end
        end
        
    end
end




%write the content into xml file
%TransformerFactory 
transformerFactory = TransformerFactory.newInstance();
%Transformer 
transformer = transformerFactory.newTransformer();
transformer.setOutputProperty(OutputKeys.INDENT, 'yes');

%DOMSource source = new DOMSource(doc);
source = DOMSource(doc);

%StreamResult 
[pathLQN, nameLQN, extLQN] = fileparts(filenameLQN);
[pathRE, nameRE, extRE] = fileparts(filenameRE); 
if isempty(nameRE)
    filename = [pathLQN,filesep,nameLQN,'_line', extLQN];
else
    filename = [pathLQN,filesep,nameLQN,'+',nameRE,'_line',extLQN];
end

result =  StreamResult(File(filename));
transformer.transform(source, result);
if verbose >= 0
    fprintf(1,'Results successfully written on file\n');
    disp(filename);
    fprintf(1,'\n');
end
