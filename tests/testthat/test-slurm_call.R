library(rslurm)
context("slurm_call")

SLURM = system('sinfo', ignore.stdout = TRUE, ignore.stderr = TRUE)
SLURM_MSG = 'Only test on Slurm head node.'

Sys.setenv(R_TESTS = "")

test_that("slurm_job name is correctly edited and output is correct", {
    if (SLURM) skip(SLURM_MSG)
    z <- 0
    sjob <- slurm_call(function(x, y) x * 2 + y + z, list(x = 5, y = 6),
                       add_objects = c('z'),
                       jobname = "test^\\* call")
    res <- get_slurm_out(sjob)
    cleanup_files(sjob)
    expect_equal(sjob$jobname, "test_call")
    expect_equal(res, 16)
})
