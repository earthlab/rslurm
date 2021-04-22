library(rslurm)
context("local slurm_call")

Sys.setenv(R_TESTS = "")

# Test slurm_call locally

msg <- capture.output({
    z <- 0
    sjob <- slurm_call(function(x, y) x * 2 + y + z, list(x = 5, y = 6),
                       global_objects = c('z'),
                       jobname = "test^\\* call", submit = FALSE)
})

test_that("slurm_job name is correctly edited", {
    expect_equal(sjob$jobname, "test_call")
})


test_that("slurm_call returns correct output", {
    skip_on_os("windows")
    sjob <- local_slurm_array(sjob)
    res <- get_slurm_out(sjob, wait = FALSE)
    expect_equal(res, 16)
})

# Pause to make sure temporary folder is free to be deleted
Sys.sleep(1)
cleanup_files(sjob, wait = FALSE)
