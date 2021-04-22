library(rslurm)
context("slurm_apply")

# Locates sinfo on system, returns "1" if not found.
SLURM = Sys.which("sinfo") == ""
SLURM_MSG = 'Only test on Slurm head node.'
SLURM_OPTS = list(time = '1')

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

# Alternative version with n as argument, to test more_args
ftest2 <- function(par_m, par_sd = 1, par_n = 10^6, ...) {
    samp <- rnorm(par_n, par_m, par_sd)
    c(s_m = mean(samp), s_sd = sd(samp))
}

# ## FIXME
# saveRDS(Sys.getenv(), 'testthat_env.RDS')
# slurm_apply(function (i) Sys.getenv(), data.frame(i = c(0)), pkgs = c(), jobname = 'test0', nodes = 1, cpus_per_node = 1)

test_that("slurm_apply gives correct output", {
    skip_on_os("windows")
    if (SLURM) skip(SLURM_MSG)
    sjob <- slurm_apply(ftest, pars, jobname = "test1", nodes = 2, 
                        cpus_per_node = 1, slurm_options = SLURM_OPTS)
    res <- get_slurm_out(sjob, "table")
    res_raw <- get_slurm_out(sjob, "raw")
    cleanup_files(sjob)
    expect_equal(pars, res, tolerance = 0.01, check.attributes = FALSE)
    expect_equal(pars, as.data.frame(do.call(rbind, res_raw)),
                 tolerance = 0.01, check.attributes = FALSE)
})

test_that("slurm_apply works with single parameter", {
    skip_on_os("windows")
    if (SLURM) skip(SLURM_MSG)
    sjob <- slurm_apply(ftest, pars[, 1, drop = FALSE], jobname = "test2", 
                        nodes = 2, cpus_per_node = 1, slurm_options = SLURM_OPTS)
    res <- get_slurm_out(sjob, "table")
    cleanup_files(sjob)
    expect_equal(pars$par_m, res$s_m, tolerance = 0.01)  
})

test_that("slurm_apply works with single row", {
    skip_on_os("windows")
    if (SLURM) skip(SLURM_MSG)
    sjob <- slurm_apply(ftest, pars[1, ], nodes = 2, jobname = "test3",
                        cpus_per_node = 1, slurm_options = SLURM_OPTS)
    res <- get_slurm_out(sjob, "table")
    cleanup_files(sjob)
    expect_equal(sjob$nodes, 1)
    expect_equal(pars[1, ], res, tolerance = 0.01, check.attributes = FALSE)  
})

test_that("slurm_apply works with single parameter and single row", {
    skip_on_os("windows")
    if (SLURM) skip(SLURM_MSG)
    sjob <- slurm_apply(ftest, pars[1, 1, drop = FALSE], jobname = "test4",
                        nodes = 2, cpus_per_node = 1,
                        slurm_options = SLURM_OPTS)
    res <- get_slurm_out(sjob, "table")
    cleanup_files(sjob)
    expect_equal(pars$par_m[1], res$s_m, tolerance = 0.01)  
})

test_that("slurm_apply correctly handles global_objects", {
    skip_on_os("windows")
    if (SLURM) skip(SLURM_MSG)
    sjob <- slurm_apply(function(i) ftest(pars[i, 1], pars[i, 2]),
                        data.frame(i = 1:nrow(pars)),
                        global_objects = c('ftest', 'pars'), jobname = "test5",
                        nodes = 2, cpus_per_node = 1,
                        slurm_options = SLURM_OPTS)
    res <- get_slurm_out(sjob, "table")
    cleanup_files(sjob)
    expect_equal(pars, res, tolerance = 0.01, check.attributes = FALSE)
})

test_that("slurm_apply correctly handles arguments given as dots", {
    skip_on_os("windows")
    if (SLURM) skip (SLURM_MSG)
    sjob <- slurm_apply(ftest2,
                        pars,
                        par_n = 10^6,
                        global_objects = c('ftest2', 'pars'), jobname = "test6",
                        nodes = 2, cpus_per_node = 1,
                        slurm_options = SLURM_OPTS)
    res <- get_slurm_out(sjob, "table")
    cleanup_files(sjob)
    expect_equal(pars, res, tolerance = 0.01, check.attributes = FALSE)
    
})