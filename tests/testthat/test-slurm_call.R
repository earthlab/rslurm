library(rslurm)
context("slurm_call")

# Locates sinfo on system, returns "1" if not found.
SLURM = Sys.which("sinfo") == ""
SLURM_MSG = 'Only test on Slurm head node.'
SLURM_OPTS = list(time = '1')

Sys.setenv(R_TESTS = "")

test_that("slurm_job name is correctly edited and output is correct", {
    skip_on_os("windows")
    if (SLURM) skip(SLURM_MSG)
    z <- 0
    sjob <- slurm_call(function(x, y) x * 2 + y + z, list(x = 5, y = 6),
                       global_objects = c('z'),
                       jobname = "test^\\* call", slurm_options = SLURM_OPTS)
    res <- get_slurm_out(sjob)
    cleanup_files(sjob)
    expect_equal(sjob$jobname, "test_call")
    expect_equal(res, 16)
})

test_that("slurm_call will handle a bytecoded function", {
    # generated in response to issue #14
    skip_on_os("windows")
    if (SLURM) skip(SLURM_MSG)
    params <- list(
        data = data.frame(
            x = seq(0, 1, by = 0.01),
            y = 0:100),
        formula = y ~ x)
    result_local <- do.call(lm, params)
    sjob <- slurm_call(lm, params, slurm_options = SLURM_OPTS)
    result_slurm <- get_slurm_out(sjob)
    cleanup_files(sjob)
    expect_equal(result_slurm$coefficients, result_local$coefficients)
})

test_that("slurm_call executes if no parameters provided", {
    skip_on_os("windows")
    if (SLURM) skip(SLURM_MSG)
    ftest <- function() sum((1:1000)^2)
    result_local <- ftest()
    sjob <- slurm_call(ftest, slurm_options = SLURM_OPTS)
    result_slurm <- get_slurm_out(sjob)
    cleanup_files(sjob)
    expect_equal(result_slurm, result_local)
})