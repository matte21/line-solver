## LINE: Performance and Reliability Modeling Engine

Website: http://line-solver.sourceforge.net/

Latest stable release: https://sourceforge.net/projects/line-solver/files/latest/download

Docker binary release (MCR): https://hub.docker.com/r/linert

[![View LINE on File Exchange](https://www.mathworks.com/matlabcentral/images/matlab-file-exchange.svg)](https://www.mathworks.com/matlabcentral/fileexchange/71486-line)

LINE is a MATLAB toolbox for performance and reliability analysis of systems and processes that can be modeled using queueing theory. The engine offers a solver-agnostic language to specify queueing networks, which therefore decouples model description from the solvers used for their solution. This is done through model-to-model transformations that automatically translate the model specification into the input format (or data structure) accepted by the target solver.

Supported models include *extended queueing networks*, both open and closed, and *layered queueing networks*. Models can be solved with either native or external solvers, the latter include [JMT](http://jmt.sourceforge.net/) and [LQNS](http://www.sce.carleton.ca/rads/lqns/). Native solvers are based on continuous-time Markov chains (CTMC), fluid ordinary differential equations, matrix analytic methods (MAM), normalizing constant analysis, and mean-value analysis (MVA). 

### Getting started (MATLAB SOURCE RELEASE)

To get started, expand the archive (or clone the repository) in the chosen installation folder.

Start MATLAB and change the active directory to the installation folder. Then add all LINE folders to the path
```
addpath(genpath(pwd))
```
Finally, run the LINE demonstrators using
```
allExamples
```

### Getting started (DOCKER BINARY RELEASE)

This version uses the royalty-free MATLAB compiler runtime to allow users without a MATLAB license to use LINE. This release can only solve JMT or LQNS models using the LINE solvers.

To get started, retrieve the LINE container:
```
docker pull linert/linux
```
Then run from the Linux shell, after downloading [example_openModel_3.jsimg](https://raw.githubusercontent.com/line-solver/line/master/examples/example_openModel_3.jsimg)
```
cat example_openModel_3.jsimg | docker run -i --rm linert/linux -i jsimg -s mva -a all -o json
```
that will print the results of getAvgTable and getAvgSysTable in JSON format.

Further help can be obtained as follows
```
docker run -i --rm linert/linux -i jsimg -h
```

### Documentation
Getting started examples and detailed instructions on how to use LINE are provided in the [User Manual](https://github.com/line-solver/line/raw/master/doc/LINE.pdf) and on the [Wiki](https://github.com/line-solver/line/wiki).

### License
LINE is released as open source under the BSD-3 license: https://raw.githubusercontent.com/line-solver/line/master/LICENSE

### Acknowledgement
The development of LINE has been partially funded by the European Commission grants FP7-318484 ([MODAClouds](http://multiclouddevops.com/)), H2020-644869 ([DICE](http://www.dice-h2020.eu/)), H2020-825040 ([RADON](http://radon-h2020.eu)), and by the EPSRC grant EP/M009211/1 ([OptiMAM](https://wp.doc.ic.ac.uk/optimam/)).
