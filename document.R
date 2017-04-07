library(tools)
library(rmarkdown)
library(devtools)

# Create a README.md for GitHub and CRAN from '../R/rlurm.R'
# by way of the '../man/rslurm-package.Rd' produced by roxygen2
Rd2HTML(parse_Rd('man/rslurm-package.Rd'), out = 'README.html')
pandoc_convert(input='README.html', to='markdown_github', output='README.md')
unlink('README.html')

# Build vignettes
build_vignettes()

## TODO
# figure out how to include Travis badge
#
# how does rmarkdown have NEWS in package index?
# maybe by including inst/NEWS.Rd, seee tools:::news2rd
