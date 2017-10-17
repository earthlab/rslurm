library(rslurm)
context("slurm_apply")

SLURM = system('sinfo', ignore.stdout = TRUE, ignore.stderr = TRUE)
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

# ## FIXME
# saveRDS(Sys.getenv(), 'testthat_env.RDS')
# slurm_apply(function (i) Sys.getenv(), data.frame(i = c(0)), pkgs = c(), jobname = 'test0', nodes = 1, cpus_per_node = 1)

test_that("slurm_apply gives correct output", {
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
    if (SLURM) skip(SLURM_MSG)
    sjob <- slurm_apply(ftest, pars[, 1, drop = FALSE], jobname = "test2", 
                        nodes = 2, cpus_per_node = 1, slurm_options = SLURM_OPTS)
    res <- get_slurm_out(sjob, "table")
    cleanup_files(sjob)
    expect_equal(pars$par_m, res$s_m, tolerance = 0.01)  
})

test_that("slurm_apply works with single row", {
    if (SLURM) skip(SLURM_MSG)
    sjob <- slurm_apply(ftest, pars[1, ], nodes = 2, jobname = "test3",
                        cpus_per_node = 1, slurm_options = SLURM_OPTS)
    res <- get_slurm_out(sjob, "table")
    cleanup_files(sjob)
    expect_equal(sjob$nodes, 1)
    expect_equal(pars[1, ], res, tolerance = 0.01, check.attributes = FALSE)  
})

test_that("slurm_apply works with single parameter and single row", {
    if (SLURM) skip(SLURM_MSG)
    sjob <- slurm_apply(ftest, pars[1, 1, drop = FALSE], jobname = "test4",
                        nodes = 2, cpus_per_node = 1,
                        slurm_options = SLURM_OPTS)
    res <- get_slurm_out(sjob, "table")
    cleanup_files(sjob)
    expect_equal(pars$par_m[1], res$s_m, tolerance = 0.01)  
})

test_that("slurm_apply correctly handles add_objects", {
    if (SLURM) skip(SLURM_MSG)
    sjob <- slurm_apply(function(i) ftest(pars[i, 1], pars[i, 2]),
                        data.frame(i = 1:nrow(pars)),
                        add_objects = c('ftest', 'pars'), jobname = "test5",
                        nodes = 2, cpus_per_node = 1,
                        slurm_options = SLURM_OPTS)
    res <- get_slurm_out(sjob, "table")
    cleanup_files(sjob)
    expect_equal(pars, res, tolerance = 0.01, check.attributes = FALSE)
})
