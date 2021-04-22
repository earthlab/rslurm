library(rslurm)
context("local slurm_map")

Sys.setenv(R_TESTS = "")
    
set.seed(123)

# Create a list of mean/sd values for normal distributions
pars <- data.frame(par_m = 1:10,
                   par_sd = seq(0.1, 1, length.out = 10))
pars_list <- split(pars, 1:10)

# Create a function to parallelize
ftest <- function(pars, par_n = 10^6, ...) {
    samp <- rnorm(par_n, pars$par_m, pars$par_sd)
    c(s_m = mean(samp), s_sd = sd(samp))
}


# Test slurm_apply locally

msg <- capture.output(
    sjob1 <- slurm_map(pars_list, ftest, jobname = "test1",
                       nodes = 2, cpus_per_node = 1, submit = FALSE)
)

test_that("slurm_map gives correct output", {
    skip_on_os("windows")
    sjob1 <- local_slurm_array(sjob1)
    res <- get_slurm_out(sjob1, "table", wait = FALSE)
    res_raw <- get_slurm_out(sjob1, "raw", wait = FALSE)
    expect_equal(pars, res, tolerance = 0.01, check.attributes = FALSE)
    expect_equal(pars, as.data.frame(do.call(rbind, res_raw)),
                 tolerance = 0.01, check.attributes = FALSE)
})


# Test for degenerate case (length 1 list)

msg <- capture.output(
    sjob2 <- slurm_map(pars_list[1], ftest, jobname = "test2", 
                       nodes = 2, cpus_per_node = 1, submit = FALSE)
)

test_that("slurm_map works with length 1 list", {
    skip_on_os("windows")
    sjob2 <- local_slurm_array(sjob2)
    res <- get_slurm_out(sjob2, "table", wait = FALSE)
    expect_equal(pars[1, ], res, tolerance = 0.01, check.attributes = FALSE)  
})

# Test slurm_map with global_objects

msg <- capture.output(
    sjob3 <- slurm_map(as.list(1:length(pars_list)),
                       function(i) ftest(pars_list[[i]]),
                       global_objects = c('ftest', 'pars_list'),
                       jobname = "test3",
                       nodes = 2, cpus_per_node = 1, submit = FALSE)
)

test_that("slurm_map correctly handles global_objects", {
    skip_on_os("windows")
    sjob3 <- local_slurm_array(sjob3)
    res <- get_slurm_out(sjob3, "table", wait = FALSE)
    expect_equal(pars, res, tolerance = 0.01, check.attributes = FALSE)
})

# Test slurm_map with dots as additional arguments

msg <- capture.output(
    sjob4 <- slurm_map(pars_list, ftest, par_n = 10^6, jobname = "test4", 
                       nodes = 2, cpus_per_node = 1, submit = FALSE)
)

test_that("slurm_map correctly handles arguments passed with ...", {
    skip_on_os("windows")
    sjob4 <- local_slurm_array(sjob4)
    res <- get_slurm_out(sjob4, "table", wait = FALSE)
    expect_equal(pars$par_m, res$s_m, tolerance = 0.01)  
})

# Cleanup all temporary files at the end
# Pause to make sure folders are free to be deleted
Sys.sleep(1)
lapply(list(sjob1, sjob2, sjob3, sjob4), cleanup_files, wait = FALSE)