
<!-- README.md is generated from README.Rmd. Please edit that file -->

# rslurm: submit R code to a SLURM cluster

<!-- badges: start -->

[![cran
checks](https://cranchecks.info/badges/worst/rslurm)](https://cran.r-project.org/web/checks/check_results_rslurm.html)
[![rstudio mirror
downloads](https://cranlogs.r-pkg.org/badges/rslurm)](https://cran.rstudio.com/web/packages/rslurm/index.html)
[![Build
Status](https://travis-ci.org/SESYNC-ci/rslurm.svg?branch=master)](https://travis-ci.org/SESYNC-ci/rslurm)
[![Project Status: WIP – Initial development is in progress, but there
has not yet been a stable, usable release suitable for the
public.](https://www.repostatus.org/badges/latest/wip.svg)](https://www.repostatus.org/#wip)
[![CRAN
status](https://www.r-pkg.org/badges/version/rslurm)](https://CRAN.R-project.org/package=rslurm)
<!-- badges: end -->

### About

Development of this R package was supported by the National
Socio-Environmental Synthesis Center (SESYNC) under funding received
from the National Science Foundation DBI-1052875.

The package was developed by Philippe Marchand (current maintainer),
with Ian Carroll and Mike Smorul contributing.

### Installation

You can install the released version of rslurm from
[CRAN](https://CRAN.R-project.org) with:

``` r
install.packages("rslurm")
#> Installing package into '/research-home/rblake/R/x86_64-pc-linux-gnu-library/3.6'
#> (as 'lib' is unspecified)
```

And the development version from
[GitHub](https://github.com/SESYNC-ci/rslurm) with:

``` r
# install.packages("devtools")
devtools::install_github("SESYNC-ci/rslurm")
#> Downloading GitHub repo SESYNC-ci/rslurm@master
#> 
#>   
   checking for file ‘/nfs/scratch/Rtmp7bhdoS/remotes336048182486/SESYNC-ci-rslurm-eb2ccca/DESCRIPTION’ ...
  
✔  checking for file ‘/nfs/scratch/Rtmp7bhdoS/remotes336048182486/SESYNC-ci-rslurm-eb2ccca/DESCRIPTION’ (2.4s)
#> 
  
─  preparing ‘rslurm’: (19.5s)
#> 
  
   checking DESCRIPTION meta-information ...
  
✔  checking DESCRIPTION meta-information
#> 
  
─  checking for LF line-endings in source and make files and shell scripts (13.4s)
#> 
  
─  checking for empty or unneeded directories
#> 
  
─  building ‘rslurm_0.4.0.9002.tar.gz’
#> 
  
   Warning: invalid uid value replaced by that for user 'nobody'
#> 
  
   
#> 
#> Installing package into '/research-home/rblake/R/x86_64-pc-linux-gnu-library/3.6'
#> (as 'lib' is unspecified)
```

### Documentation

Package documentation is accessible from the R console through
`package?rslurm` and
[online](https://cran.r-project.org/package=rslurm).

### Example

Note that job submission is only possible on a system with access to a
Slurm workload manager (i.e. a system where the command line utilities
`squeue` or `sinfo` return information from a Slurm head node).

To illustrate a typical rslurm workflow, we use a simple function that
takes a mean and standard deviation as parameters, generates a million
normal deviates and returns the sample mean and standard deviation.

``` r
test_func <- function(par_mu, par_sd) {
    samp <- rnorm(10^6, par_mu, par_sd)
    c(s_mu = mean(samp), s_sd = sd(samp))
}
```

We then create a parameter data frame where each row is a parameter set
and each column matches an argument of the function.

``` r
pars <- data.frame(par_mu = 1:10,
                   par_sd = seq(0.1, 1, length.out = 10))
```

We can now pass that function and the parameters data frame to
`slurm_apply`, specifiying the number of cluster nodes to use and the
number of CPUs per node.

``` r
library(rslurm)
sjob <- slurm_apply(test_func, pars, jobname = 'test_apply',
                    nodes = 2, cpus_per_node = 2, submit = FALSE)
#> Submission scripts output in directory _rslurm_test_apply
```

The output of `slurm_apply` is a `slurm_job` object that stores a few
pieces of information (job name, job ID, and the number of nodes) needed
to retrieve the job’s output.

See [vignette](https://cran.r-project.org/package=rslurm) for more
information.
