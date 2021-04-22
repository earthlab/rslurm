library(rslurm)
context("local slurm_apply")

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

# Test slurm_apply locally

msg <- capture.output(
    sjob1 <- slurm_apply(ftest, pars, jobname = "test1", nodes = 2, 
                         cpus_per_node = 1, submit = FALSE)
)

test_that("slurm_apply gives correct output", {
    skip_on_os("windows")
    sjob1 <- local_slurm_array(sjob1)
    res <- get_slurm_out(sjob1, "table", wait = FALSE)
    res_raw <- get_slurm_out(sjob1, "raw", wait = FALSE)
    expect_equal(pars, res, tolerance = 0.01, check.attributes = FALSE)
    expect_equal(pars, as.data.frame(do.call(rbind, res_raw)),
                 tolerance = 0.01, check.attributes = FALSE)
})


# Test for degenerate cases (single parameter and/or single row)

msg <- capture.output(
    sjob2 <- slurm_apply(ftest, pars[, 1, drop = FALSE], jobname = "test2", 
                         nodes = 2, cpus_per_node = 1, submit = FALSE)
)

test_that("slurm_apply works with single parameter", {
    skip_on_os("windows")
    sjob2 <- local_slurm_array(sjob2)
    res <- get_slurm_out(sjob2, "table", wait = FALSE)
    expect_equal(pars$par_m, res$s_m, tolerance = 0.01)  
})

msg <- capture.output(
    sjob3 <- slurm_apply(ftest, pars[1, ], nodes = 2, jobname = "test3",
                         cpus_per_node = 1, submit = FALSE)
)

test_that("slurm_apply works with single row", {
    skip_on_os("windows")
    sjob3 <- local_slurm_array(sjob3)
    res <- get_slurm_out(sjob3, "table", wait = FALSE)
    expect_equal(sjob3$nodes, 1)
    expect_equal(pars[1, ], res, tolerance = 0.01, check.attributes = FALSE)  
})

msg <- capture.output(
    sjob4 <- slurm_apply(ftest, pars[1, 1, drop = FALSE], jobname = "test4",
                         nodes = 2, cpus_per_node = 1, submit = FALSE)
)

test_that("slurm_apply works with single parameter and single row", {
    skip_on_os("windows")
    sjob4 <- local_slurm_array(sjob4)
    res <- get_slurm_out(sjob4, "table", wait = FALSE)
    expect_equal(pars$par_m[1], res$s_m, tolerance = 0.01)  
})

# Test slurm_apply with global_objects

msg <- capture.output(
    sjob5 <- slurm_apply(function(i) ftest(pars[i, 1], pars[i, 2]),
                         data.frame(i = 1:nrow(pars)),
                         global_objects = c('ftest', 'pars'), jobname = "test5",
                         nodes = 2, cpus_per_node = 1, submit = FALSE)
)

test_that("slurm_apply correctly handles global_objects", {
    skip_on_os("windows")
    sjob5 <- local_slurm_array(sjob5)
    res <- get_slurm_out(sjob5, "table", wait = FALSE)
    expect_equal(pars, res, tolerance = 0.01, check.attributes = FALSE)
})

# Test slurm_apply with ... arguments

msg <- capture.output(
    sjob6 <- slurm_apply(ftest2,
                         pars,
                         par_n = 10^6,
                         global_objects = c('ftest2', 'pars'), jobname = "test6",
                         nodes = 2, cpus_per_node = 1, submit = FALSE)
)

test_that("slurm_apply correctly handles arguments passed with ...", {
    skip_on_os("windows")
    sjob6 <- local_slurm_array(sjob6)
    res <- get_slurm_out(sjob6, "table", wait = FALSE)
    expect_equal(pars, res, tolerance = 0.01, check.attributes = FALSE)
})

# Cleanup all temporary files at the end
# Pause to make sure folders are free to be deleted
Sys.sleep(1)
lapply(list(sjob1, sjob2, sjob3, sjob4, sjob5, sjob6), cleanup_files, wait = FALSE)