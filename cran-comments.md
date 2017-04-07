This is a minor update to the package to add a new feature, update the vignette, and fix structure and bugs.

The 'rslurm.Rmd' vignette (formerly 'rslurm-vignette.Rmd') now only builds on a SLURM head node. The built vignette in inst/doc can be used as is. To prevent build errors, 'BuildVignette: no' is in the description and vignettes are matched in .Buildignore. This gives the Note, but I see no way around it.

## Tested on

Ubuntu 14.04 with R 3.3 (SLURM head node)
Ubuntu 12.04 with R 3.3 (travis-ci)
macOS 10.12 with R 3.3 (local machine)
win-builder (release and devel)

## R CMD check

0 errors | 0 warnings | 1 notes

* checking for old-style vignette sources ... NOTE
Vignette sources only in ‘inst/doc’:
  ‘rslurm.Rmd’
A ‘vignettes’ directory is required as from R 3.1.0
and these will not be indexed nor checked