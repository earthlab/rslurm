library(rslurm)
context("slurm_call")

Sys.setenv(R_TESTS = "")

# Test slurm_call locally

msg <- capture.output(
    sjob <- slurm_call(function(x, y) x * 2 + y, list(x = 5, y = 6), 
                       jobname = "test^\\* call", submit = FALSE)
)

test_that("slurm_job name is correctly edited", {
    expect_equal(sjob$jobname, "test_call")
})

olddir <- getwd()
rscript_path <- file.path(R.home("bin"), "Rscript")
setwd(paste0("_rslurm_", sjob$jobname))
tryCatch(system(paste(rscript_path, "--vanilla slurm_run.R")), 
         finally = setwd(olddir))
res <- get_slurm_out(sjob)

test_that("slurm_call returns correct output", {
    expect_equal(res, 16)
})

# Pause to make sure temporary folder is free to be deleted
Sys.sleep(1)
cleanup_files(sjob)
