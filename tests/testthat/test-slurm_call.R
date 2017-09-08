library(rslurm)
context("slurm_call")

skip_if_not(system('sinfo') == 0, 'Cannot run test with Slurm workload manager.')

Sys.setenv(R_TESTS = "")

# Test slurm_call

z <- 0
sjob <- slurm_call(function(x, y) x * 2 + y + z, list(x = 5, y = 6),
                   add_objects = c('z'),
                   jobname = "test^\\* call")

test_that("slurm_job name is correctly edited", {
    expect_equal(sjob$jobname, "test_call")
})

res <- get_slurm_out(sjob)

test_that("slurm_call returns correct output", {
    expect_equal(res, 16)
})

# Pause to make sure temporary folder is free to be deleted
cleanup_files(sjob)
