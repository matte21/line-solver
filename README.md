## LINE: Queueing Theory Algorithms

Website: http://line-solver.sourceforge.net/

Latest stable release: https://sourceforge.net/projects/line-solver/files/latest/download

Docker binary release (MCR): https://hub.docker.com/r/linemcr/cli

[![License](https://img.shields.io/badge/License-BSD%203--Clause-red.svg)](https://github.com/imperial-qore/line-solver/blob/master/LICENSE)
[![Hits](https://hits.seeyoufarm.com/api/count/incr/badge.svg?url=https%3A%2F%2Fgithub.com%2Fimperial-qore%2Fline-solver&count_bg=%23FFC401&title_bg=%23555555&icon=&icon_color=%23E7E7E7&title=hits&edge_flat=false)](https://hits.seeyoufarm.com)
[![View LINE on File Exchange](https://www.mathworks.com/matlabcentral/images/matlab-file-exchange.svg)](https://www.mathworks.com/matlabcentral/fileexchange/71486-line)

LINE is an open source library to analyze queueing systems and queueing network models via analytical methods and simulation. LINE supports many algorithms for the solution of open queueing systems (e.g., M/M/1, M/M/k, M/G/1, ...), open and closed queueing networks, and layered queueing networks. LINE can be run as a royalty-free Docker container or as a MATLAB toolbox. Additional information is available in the [LINE wiki](https://github.com/imperial-qore/line-solver/wiki).

### Installation

To install LINE, first expand the archive (or clone the repository) in the chosen installation folder. Then start MATLAB, change the active directory to the installation folder and run:
```
lineInstall
```

### Getting started
To begin using LINE, add all LINE folders to the path using the following command:
```
lineStart
```
The last command is required at the beginning of every MATLAB session. You can now use LINE. 

For example, to solve a basic M/M/1 queue by simulation, type:
```
model = Network('M/M/1');
source = Source(model, 'mySource');
queue = Queue(model, 'myQueue', SchedStrategy.FCFS);
sink = Sink(model, 'mySink');

oclass = OpenClass(model, 'myClass');
source.setArrival(oclass, Exp(1));
queue.setService(oclass, Exp(2));

model.link(Network.serialRouting(source,queue,sink));

AvgTable = SolverJMT(model,'seed',23000).getAvgTable
```

To run other demonstrators type instead:
```
allExamples
```
Additional getting started examples and instructions can be found in the [User Manual](https://github.com/line-solver/line/raw/master/doc/LINE.pdf) and on the [Wiki](https://github.com/line-solver/line/wiki).


### License
LINE is released as open source under the [BSD-3 license](https://raw.githubusercontent.com/line-solver/line/master/LICENSE).

### Acknowledgement
The development of LINE has been partially funded by the European Commission grants FP7-318484 ([MODAClouds](http://multiclouddevops.com/)), H2020-644869 ([DICE](http://www.dice-h2020.eu/)), H2020-825040 ([RADON](http://radon-h2020.eu)), and by the EPSRC grant EP/M009211/1 ([OptiMAM](https://wp.doc.ic.ac.uk/optimam/)).
