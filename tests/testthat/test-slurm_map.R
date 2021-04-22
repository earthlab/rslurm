library(rslurm)
context("slurm_map")

# Locates sinfo on system, returns "1" if not found.
SLURM = Sys.which("sinfo") == ""
SLURM_MSG = 'Only test on Slurm head node.'
SLURM_OPTS = list(time = '1')

Sys.setenv(R_TESTS = "")
    
set.seed(123)

# Create a list of paired mean/sd values for normal distributions
pars <- data.frame(par_m = 1:10,
                   par_sd = seq(0.1, 1, length.out = 10))
pars_list <- split(pars, 1:10)

# Create a function to parallelize
ftest <- function(pars, par_n = 10^6, ...) {
    samp <- rnorm(par_n, pars$par_m, pars$par_sd)
    c(s_m = mean(samp), s_sd = sd(samp))
}

# ## FIXME
# saveRDS(Sys.getenv(), 'testthat_env.RDS')
# slurm_apply(function (i) Sys.getenv(), data.frame(i = c(0)), pkgs = c(), jobname = 'test0', nodes = 1, cpus_per_node = 1)

test_that("slurm_map gives correct output", {
    skip_on_os("windows")
    if (SLURM) skip(SLURM_MSG)
    sjob <- slurm_map(pars_list, ftest, jobname = "test1", nodes = 2, 
                      cpus_per_node = 1, slurm_options = SLURM_OPTS)
    res <- get_slurm_out(sjob, "table")
    res_raw <- get_slurm_out(sjob, "raw")
    cleanup_files(sjob)
    expect_equal(pars, res, tolerance = 0.01, check.attributes = FALSE)
    expect_equal(pars, as.data.frame(do.call(rbind, res_raw)),
                 tolerance = 0.01, check.attributes = FALSE)
})

test_that("slurm_map works with single list element", {
    skip_on_os("windows")
    if (SLURM) skip(SLURM_MSG)
    sjob <- slurm_map(pars_list[1], ftest, nodes = 2, jobname = "test2",
                      cpus_per_node = 1, slurm_options = SLURM_OPTS)
    res <- get_slurm_out(sjob, "table")
    cleanup_files(sjob)
    expect_equal(sjob$nodes, 1)
    expect_equal(pars[1, ], res, tolerance = 0.01, check.attributes = FALSE)  
})

test_that("slurm_map correctly handles global_objects", {
    skip_on_os("windows")
    if (SLURM) skip(SLURM_MSG)
    sjob <- slurm_map(as.list(1:length(pars_list)),
                      function(i) ftest(pars_list[[i]]),
                      global_objects = c('ftest', 'pars_list'), jobname = "test3",
                      nodes = 2, cpus_per_node = 1,
                      slurm_options = SLURM_OPTS)
    res <- get_slurm_out(sjob, "table")
    cleanup_files(sjob)
    expect_equal(pars, res, tolerance = 0.01, check.attributes = FALSE)
})

test_that("slurm_map correctly handles arguments passed with ...", {
    skip_on_os("windows")
    if (SLURM) skip (SLURM_MSG)
    sjob <- slurm_map(pars_list, ftest,
                      par_n = 10^6, jobname = "test4",
                      nodes = 2, cpus_per_node = 1,
                      slurm_options = SLURM_OPTS)
    res <- get_slurm_out(sjob, "table")
    cleanup_files(sjob)
    expect_equal(pars, res, tolerance = 0.01, check.attributes = FALSE)
    
})
