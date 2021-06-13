## LINE: Performance and Reliability Modeling Engine

Website: http://line-solver.sourceforge.net/

Latest stable release: https://sourceforge.net/projects/line-solver/files/latest/download

Docker binary release (MCR): https://hub.docker.com/r/linemcr/cli

[![License](https://img.shields.io/badge/License-BSD%203--Clause-red.svg)](https://github.com/imperial-qore/line-solver/blob/master/LICENSE)
![Python 3.7, 3.8](https://img.shields.io/badge/python-3.7%20%7C%203.8-blue.svg)
[![Hits](https://hits.seeyoufarm.com/api/count/incr/badge.svg?url=https%3A%2F%2Fgithub.com%2Fimperial-qore%2Fline-solver&count_bg=%23FFC401&title_bg=%23555555&icon=&icon_color=%23E7E7E7&title=hits&edge_flat=false)](https://hits.seeyoufarm.com)

[![View LINE on File Exchange](https://www.mathworks.com/matlabcentral/images/matlab-file-exchange.svg)](https://www.mathworks.com/matlabcentral/fileexchange/71486-line)

LINE is a MATLAB toolbox for performance and reliability analysis of systems and processes that can be modeled using queueing theory. The engine offers a solver-agnostic language to specify queueing networks, which therefore decouples model description from the solvers used for their solution. This is done through model-to-model transformations that automatically translate the model specification into the input format (or data structure) accepted by the target solver.

Supported models include *extended queueing networks*, both open and closed, and *layered queueing networks*. Models can be solved with either native or external solvers, the latter include [JMT](http://jmt.sourceforge.net/) and [LQNS](http://www.sce.carleton.ca/rads/lqns/). Native solvers are based on continuous-time Markov chains (CTMC), fluid ordinary differential equations, matrix analytic methods (MAM), normalizing constant analysis, and mean-value analysis (MVA). 

### Getting started (MATLAB SOURCE)

To get started, expand the archive (or clone the repository) in the chosen installation folder.

Start MATLAB and change the active directory to the installation folder. Then add all LINE folders to the path
```
addpath(genpath(pwd))
```
Finally, run the LINE demonstrators using
```
allExamples
```

### Getting started (DOCKER SERVER)

This binary release uses the royalty-free [MATLAB compiler runtime](https://www.mathworks.com/products/compiler/matlab-runtime.html) to enable users without a MATLAB license to use the main features of LINE. This release can only solve models specified using the [JMT](http://jmt.sf.net) or [LQNS](http://www.sce.carleton.ca/rads/lqns/) input file formats.

To get started, retrieve the LINE container:
```
docker pull linemcr/cli
```
Let us first run the line container in client-server model 
```
docker run -i -p 127.0.0.1:5463:5463/tcp  --rm linemcr/cli -p 5463
```
bootstraps the server. To solve a layered queueing network (LQN), after downloading a LQN example model [ofbizExample.xml](https://raw.githubusercontent.com/imperial-qore/line/master/examples/ofbizExample.xml), we issue a request to the engine using LINE's [websocket client](https://github.com/imperial-qore/line-solver/raw/master/src/cli/websocket/lineclient.jar). 
```
cat ofbizExample.xml | java -jar lineclient.jar 127.0.0.1 5463
```
Note that the first invocation tends to be slightly slower than the following ones.

The command will print in JSON format the results of the mean performance metrics calculation functions of LINE, getAvgTable and getAvgSysTable.

### Getting started (DOCKER CLI)

It is also possible to run LINE in direct CLI mode, but incurring a longer bootstrap time due to the MATLAB compiler runtime startup, for example:
```
cat ofbizExample.xml | docker run -i --rm linemcr/cli -i xml -s ln -a all -o json
```
We can also solve [JMT](http://jmt.sf.net) example models. We first download [example_openModel_3.jsimg](https://raw.githubusercontent.com/line-solver/line/master/examples/example_openModel_3.jsimg) to a local directory and then run
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
