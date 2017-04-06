This is a minor update to the package to add a new feature, update the vignette, and fix bugs.

The 'overview.Rmd' vignette (formerly 'rslurm-vignette.Rmd') now only builds on a SLURM head node. The built vignette in inst/doc can be used as is.

## Tested on

Ubuntu 14.04 with R 3.3 (rstudio.sesync.org, SLURM head node)
Ubuntu 12.04 with R 3.3 (travis-ci)
macOS 10.12 with R 3.3 (local machine, R CMD build with '--no-build-vignettes', R CMD check with '--no-vignettes')
win-builder (release and devel, after manual removal of 'overview.Rmd' vignette)

## R CMD check

0 errors | 0 warnings | 0 notes
