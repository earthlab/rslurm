library(rslurm)
context("slurm_call")

SLURM = system('sinfo', ignore.stdout = TRUE, ignore.stderr = TRUE)
SLURM_MSG = 'Only test on Slurm head node.'
SLURM_OPTS = list(time = '1')

Sys.setenv(R_TESTS = "")

test_that("slurm_job name is correctly edited and output is correct", {
    if (SLURM) skip(SLURM_MSG)
    z <- 0
    sjob <- slurm_call(function(x, y) x * 2 + y + z, list(x = 5, y = 6),
                       add_objects = c('z'),
                       jobname = "test^\\* call", slurm_options = SLURM_OPTS)
    res <- get_slurm_out(sjob)
    cleanup_files(sjob)
    expect_equal(sjob$jobname, "test_call")
    expect_equal(res, 16)
})

test_that("slurm_call will handle a bytecoded function", {
    # generated in response to issue #14
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
    expect_equal(result_slurm$coeficients, result_local$coeficients)
})
