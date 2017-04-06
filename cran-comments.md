This is a minor update to the package to add a new feature, update vignette, and fix bugs.

The 'overview.Rmd' vignette only works on a SLURM head node. The built vignette in inst/doc should be used instead of any vignette built on CRAN.

## Tested on

?win-builder (devel and release)
Ubuntu 12.04 with R 3.3 (on travis-ci)
macOS 10.12 with R 3.3 (local machine)

## R CMD check results

1 error | 0 warnings | 0 notes

The error results from building the 'overview.Rmd' vignette without a SLURM workload manager.