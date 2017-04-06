## ------------------------------------------------------------------------
test_func <- function(par_mu, par_sd) {
    samp <- rnorm(10^6, par_mu, par_sd)
    c(s_mu = mean(samp), s_sd = sd(samp))
}

## ------------------------------------------------------------------------
pars <- data.frame(par_mu = 1:10,
                   par_sd = seq(0.1, 1, length.out = 10))
head(pars, 3)

## ------------------------------------------------------------------------
library(rslurm)
sjob <- slurm_apply(test_func, pars, jobname = "test_job", 
                    nodes = 2, cpus_per_node = 2)

## ------------------------------------------------------------------------
res <- get_slurm_out(sjob, outtype = "table")
head(res, 3)

## ------------------------------------------------------------------------
res_raw <- get_slurm_out(sjob, outtype = "raw", wait = FALSE)
res_raw[1:3]

## ------------------------------------------------------------------------
dir("_rslurm_test_job")

## ----echo=FALSE----------------------------------------------------------
cleanup_files(sjob)

## ------------------------------------------------------------------------
sjob <- slurm_call(test_func, list(par_mu = 5, par_sd = 1))

## ----echo=FALSE----------------------------------------------------------
cleanup_files(sjob)

## ----echo=FALSE----------------------------------------------------------
obj_list <- list(NULL)
func <- function(obj) {}

## ------------------------------------------------------------------------
sjob <- slurm_apply(function(i) func(obj_list[[i]]), 
                    data.frame(i = seq_along(obj_list)),
                    add_objects = c("func", "obj_list"),
                    nodes = 2, cpus_per_node = 2)

## ----echo=FALSE----------------------------------------------------------
cleanup_files(sjob)

## ------------------------------------------------------------------------
sjob <- slurm_apply(test_func, pars, 
                    slurm_options = list(time = "1:00:00", share = TRUE))

## ----echo=FALSE----------------------------------------------------------
cleanup_files(sjob)

