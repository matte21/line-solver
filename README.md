## LINE: Queueing Theory Algorithms

Website: http://line-solver.sourceforge.net/

Latest stable release: https://sourceforge.net/projects/line-solver/files/latest/download

Docker binary release (MCR): https://hub.docker.com/r/linemcr/cli

[![License](https://img.shields.io/badge/License-BSD%203--Clause-red.svg)](https://github.com/imperial-qore/line-solver/blob/master/LICENSE)
[![Hits](https://hits.seeyoufarm.com/api/count/incr/badge.svg?url=https%3A%2F%2Fgithub.com%2Fimperial-qore%2Fline-solver&count_bg=%23FFC401&title_bg=%23555555&icon=&icon_color=%23E7E7E7&title=hits&edge_flat=false)](https://hits.seeyoufarm.com)
[![View LINE on File Exchange](https://www.mathworks.com/matlabcentral/images/matlab-file-exchange.svg)](https://www.mathworks.com/matlabcentral/fileexchange/71486-line)

LINE is a MATLAB toolbox offering computational algorithms for queueing theory. LINE supports the solution of open queueing systems (e.g., M/M/1, M/M/k, M/G/1, ...), open and closed queueing networks, and layered queueing networks. Analysis techniques include analytical approximations, exact formulas and discrete-event simulation. Detailed information is available in the [LINE wiki](https://github.com/imperial-qore/line-solver/wiki).

The engine offers a language to specify queueing networks that decouples model description from the choice of solver used for its solution. Model-to-model transformations enable the use of either native or external solvers, such as [JMT](http://jmt.sourceforge.net/) and [LQNS](http://www.sce.carleton.ca/rads/lqns/). Native solvers are based on continuous-time Markov chains (CTMC), fluid ordinary differential equations, matrix analytic methods (MAM), normalizing constant analysis, and mean-value analysis (MVA).

Advanced features include nodes to describe caching, randomly-evolving environments, computation of response time percentiles, and transient solutions.

### Installation (MATLAB SOURCE)

To install LINE, expand the archive (or clone the repository) in the chosen installation folder.

Start MATLAB, change the active directory to the installation folder and run only the first time:
```
lineInstall
```

### Getting started (MATLAB SOURCE)
To begin using LINE, add all LINE folders to the path using the following command:
```
lineStart
```
The last command is required at the begin of every MATLAB session. You can now use LINE. For example, run the LINE demonstrators using
```
allExamples
```

### Getting started (DOCKER SERVER)

This binary release uses the royalty-free [MATLAB compiler runtime](https://www.mathworks.com/products/compiler/matlab-runtime.html) to enable users without a MATLAB license to use the main features of LINE. This release can only solve models specified using the [JMT](http://jmt.sf.net) or [LQNS](http://www.sce.carleton.ca/rads/lqns/) input file formats.

To get started, retrieve the LINE container:
```
docker pull linemcr/cli
```
Let us first run the line container in client-server model by bootstrapping the server first
```
docker run -i -p 127.0.0.1:5463:5463/tcp  --rm linemcr/cli -p 5463
```
To solve a layered queueing network (LQN), after downloading a LQN example model [ofbizExample.xml](https://raw.githubusercontent.com/imperial-qore/line/master/examples/ofbizExample.xml), we issue a request to the server from LINE's [websocket client](https://github.com/imperial-qore/line-solver/raw/master/src/cli/websocket/lineclient.jar). 
```
cat ofbizExample.xml | java -jar lineclient.jar 127.0.0.1 5463 -i lqnx
```
Note that the first invocation tends to be slightly slower than the following ones.

The command will print in JSON format the results of the mean performance metrics calculation functions of LINE, getAvgTable and getAvgSysTable.

### Getting started (DOCKER CLI)

It is also possible to run LINE in direct CLI mode, but incurring a longer bootstrap time due to the MATLAB compiler runtime startup, for example:
```
cat ofbizExample.xml | docker run -i --rm linemcr/cli -i lqnx -s ln -a all -o json
```
We can also solve [JMT](http://jmt.sf.net) example models. First download [example_openModel_3.jsimg](https://raw.githubusercontent.com/line-solver/line/master/examples/example_openModel_3.jsimg) to a local directory and then run
```
cat example_openModel_3.jsimg | docker run -i --rm linemcr/cli -i jsimg -s mva -a all -o json
```

### Documentation
Getting started examples and detailed instructions on how to use LINE are provided in the [User Manual](https://github.com/line-solver/line/raw/master/doc/LINE.pdf) and on the [Wiki](https://github.com/line-solver/line/wiki).

A number of functions in MATLAB document their I/O behavior, e.g.:
```
>> help Solver.accurateOdeSolver
  FUN = accurateOdeSolver()
  Return default high-accuracy non-stiff solver
```

Further help on the Docker container options can instead be obtained as follows
```
docker run -i --rm linemcr/cli -h
```

### License
LINE is released as open source under the BSD-3 license: https://raw.githubusercontent.com/line-solver/line/master/LICENSE

### Acknowledgement
The development of LINE has been partially funded by the European Commission grants FP7-318484 ([MODAClouds](http://multiclouddevops.com/)), H2020-644869 ([DICE](http://www.dice-h2020.eu/)), H2020-825040 ([RADON](http://radon-h2020.eu)), and by the EPSRC grant EP/M009211/1 ([OptiMAM](https://wp.doc.ic.ac.uk/optimam/)).
