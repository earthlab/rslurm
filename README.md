# rslurm: submit R code to a SLURM cluster

[![cran checks](https://cranchecks.info/badges/worst/rslurm)](https://cran.r-project.org/web/checks/check_results_rslurm.html)
[![rstudio mirror downloads](https://cranlogs.r-pkg.org/badges/rslurm)](https://cran.rstudio.com/web/packages/rslurm/index.html)
[![Build Status](https://travis-ci.org/SESYNC-ci/rslurm.svg?branch=master)](https://travis-ci.org/SESYNC-ci/rslurm)
[![Project Status: WIP – Initial development is in progress, but there has not yet been a stable, usable release suitable for the public.](https://www.repostatus.org/badges/latest/wip.svg)](https://www.repostatus.org/#wip)

### About

Development of this R package was supported by the National Socio-Environmental
Synthesis Center (SESYNC) under funding received from the National Science
Foundation DBI-1052875.

The package was developed by Philippe Marchand (current maintainer), with Ian Carroll and Mike Smorul contributing.

### Installation

Install the package from CRAN with `install.packages('rslurm')`.

Note that job submission is only possible on a system with access to a Slurm workload manager
(i.e. a system where the command line utilities `squeue` or `sinfo` return
information from a Slurm head node).

### Documentation

Package documentation is accessible from the R console through `package?rslurm`
and [online](https://cran.r-project.org/package=rslurm).
