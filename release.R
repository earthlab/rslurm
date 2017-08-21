library(devtools)

# Document from R/*.R
document()

# Build vignettes
build_vignettes()

# Build
pkg <- build(path='~/tmp/')
check_built(pkg)
