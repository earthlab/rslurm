library(tools)
library(rmarkdown)
library(devtools)
library(xml2)

# Document from R/*.R
document()

# Create a README.md for GitHub and CRAN from '../R/rlurm.R'
# by way of the '../man/rslurm-package.Rd' produced by roxygen2
Rd2HTML(parse_Rd('man/rslurm-package.Rd'), out = 'README.html')
html <- read_html('README.html')
table <- xml_find_first(html, '//table')
xml_remove(table)
h2 <- xml_find_first(html, '//h2')
img <- read_xml('<img src="https://travis-ci.org/SESYNC-ci/rslurm.svg?branch=master"/>')
xml_add_sibling(h2, img, where='after')
write_html(html, 'README.html')
pandoc_convert(input='README.html', to='markdown_github', output='README.md')
unlink('README.html')

# Remove duplicate documentation for rslurm and rslurm-package from index and search
system('sed -i "/alias{rslurm-package}/d" man/rslurm-package.Rd')

# Build
pkg <- build()
check_built(pkg)
