library(rslurm)
context("slurm_apply")

if (system('sinfo')) skip('Only run test on a Slurm head node.')

Sys.setenv(R_TESTS = "")
    
set.seed(123)

# Create a data frame of mean/sd values for normal distributions
pars <- data.frame(par_m = 1:10,
                   par_sd = seq(0.1, 1, length.out = 10))

# Create a function to parallelize
ftest <- function(par_m, par_sd = 1, ...) {
    samp <- rnorm(10^6, par_m, par_sd)
    c(s_m = mean(samp), s_sd = sd(samp))
}


# slurm libraries
test0 <- function(i) Sys.getenv()
slurm_apply(test0, data.frame(i = c(0)), pkgs = c(), jobname = 'test0', nodes = 1, cpus_per_node = 1)

# Test slurm_apply

sjob1 <- slurm_apply(ftest, pars, jobname = "test1", nodes = 2, 
                     cpus_per_node = 1)
res <- get_slurm_out(sjob1, "table")
res_raw <- get_slurm_out(sjob1, "raw")
test_that("slurm_apply gives correct output", {
    expect_equal(pars, res, tolerance = 0.01, check.attributes = FALSE)
    expect_equal(pars, as.data.frame(do.call(rbind, res_raw)),
                 tolerance = 0.01, check.attributes = FALSE)
})


# Test for degenerate cases (single parameter and/or single row)

sjob2 <- slurm_apply(ftest, pars[, 1, drop = FALSE], jobname = "test2", 
                     nodes = 2, cpus_per_node = 1)
res <- get_slurm_out(sjob2, "table")
test_that("slurm_apply works with single parameter", {
    expect_equal(pars$par_m, res$s_m, tolerance = 0.01)  
})

sjob3 <- slurm_apply(ftest, pars[1, ], nodes = 2, jobname = "test3",
                     cpus_per_node = 1)
res <- get_slurm_out(sjob3, "table")
test_that("slurm_apply works with single row", {
    expect_equal(sjob3$nodes, 1)
    expect_equal(pars[1, ], res, tolerance = 0.01, check.attributes = FALSE)  
})

sjob4 <- slurm_apply(ftest, pars[1, 1, drop = FALSE], jobname = "test4",
                     nodes = 2, cpus_per_node = 1)
res <- get_slurm_out(sjob4, "table")
test_that("slurm_apply works with single parameter and single row", {
    expect_equal(pars$par_m[1], res$s_m, tolerance = 0.01)  
})

# Test slurm_apply with add_objects

sjob5 <- slurm_apply(function(i) ftest(pars[i, 1], pars[i, 2]),
                     data.frame(i = 1:nrow(pars)),
                     add_objects = c('ftest', 'pars'), jobname = "test5",
                     nodes = 2, cpus_per_node = 1)
res <- get_slurm_out(sjob5, "table")
test_that("slurm_apply correctly handles add_objects", {
    expect_equal(pars, res, tolerance = 0.01, check.attributes = FALSE)
})


# Cleanup all temporary files at the end
lapply(list(sjob1, sjob2, sjob3, sjob4, sjob5), cleanup_files)