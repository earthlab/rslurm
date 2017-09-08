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


# Test slurm_apply locally

msg <- capture.output(
    sjob1 <- slurm_apply(ftest, pars, jobname = "test1", nodes = 2, 
                         cpus_per_node = 1, submit = FALSE)
)
sjob1 <- local_slurm_array(sjob1)
res <- get_slurm_out(sjob1, "table", wait = FALSE)
res_raw <- get_slurm_out(sjob1, "raw", wait = FALSE)
test_that("slurm_apply gives correct output", {
    expect_equal(pars, res, tolerance = 0.01, check.attributes = FALSE)
    expect_equal(pars, as.data.frame(do.call(rbind, res_raw)),
                 tolerance = 0.01, check.attributes = FALSE)
})


# Test for degenerate cases (single parameter and/or single row)

msg <- capture.output(
    sjob2 <- slurm_apply(ftest, pars[, 1, drop = FALSE], jobname = "test2", 
                         nodes = 2, cpus_per_node = 1, submit = FALSE)
)
sjob2 <- local_slurm_array(sjob2)
res <- get_slurm_out(sjob2, "table", wait = FALSE)
test_that("slurm_apply works with single parameter", {
    expect_equal(pars$par_m, res$s_m, tolerance = 0.01)  
})

msg <- capture.output(
    sjob3 <- slurm_apply(ftest, pars[1, ], nodes = 2, jobname = "test3",
                         cpus_per_node = 1, submit = FALSE)
)
sjob3 <- local_slurm_array(sjob3)
res <- get_slurm_out(sjob3, "table", wait = FALSE)
test_that("slurm_apply works with single row", {
    expect_equal(sjob3$nodes, 1)
    expect_equal(pars[1, ], res, tolerance = 0.01, check.attributes = FALSE)  
})

msg <- capture.output(
    sjob4 <- slurm_apply(ftest, pars[1, 1, drop = FALSE], jobname = "test4",
                         nodes = 2, cpus_per_node = 1, submit = FALSE)
)
sjob4 <- local_slurm_array(sjob4)
res <- get_slurm_out(sjob4, "table", wait = FALSE)
test_that("slurm_apply works with single parameter and single row", {
    expect_equal(pars$par_m[1], res$s_m, tolerance = 0.01)  
})

# Test slurm_apply with add_objects

msg <- capture.output(
    sjob5 <- slurm_apply(function(i) ftest(pars[i, 1], pars[i, 2]),
                         data.frame(i = 1:nrow(pars)),
                         add_objects = c('ftest', 'pars'), jobname = "test5",
                         nodes = 2, cpus_per_node = 1, submit = FALSE)
)
sjob5 <- local_slurm_array(sjob5)
res <- get_slurm_out(sjob5, "table", wait = FALSE)
test_that("slurm_apply correctly handles add_objects", {
    expect_equal(pars, res, tolerance = 0.01, check.attributes = FALSE)
})


# Cleanup all temporary files at the end
# Pause to make sure folders are free to be deleted
Sys.sleep(1)
lapply(list(sjob1, sjob2, sjob3, sjob4, sjob5), cleanup_files, wait = FALSE)