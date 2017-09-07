### Status

Pre-release:
[![Build Status](https://travis-ci.org/SESYNC-ci/rslurm.svg?branch=master)](https://travis-ci.org/SESYNC-ci/rslurm)

CRAN checks:
[rslurm results](https://cran.r-project.org/web/checks/check_results_rslurm.html)

### About

Development of this R package was supported by the National Socio-Environmental
Synthesis Center (SESYNC) under funding received from the National Science
Foundation DBI-1052875.

The package was developed by Philippe Marchand, with Ian Carroll (current
maintainer) and Mike Smorul contributing.

### Installation

Install the package from R with `install.packages('rslurm')`. Note that job
submission is only possible on a system with access to a Slurm workload manager
(i.e. a system where the command line utilities `squeue` or `sinfo` return
information from a Slurm head node).

### Documentation

Package documentation is accessible from the R console through `package?rslurm`
and [online](https://cran.r-project.org/package=rslurm).
