.tmplib <- lapply(c('base','methods','datasets','utils','grDevices','graphics','stats','testthat','rslurm'), 
                  library, character.only = TRUE, quietly = TRUE)
.rslurm_func <- function(par_m, par_sd = 1, ...) {
    samp <- rnorm(10^6, par_m, par_sd)
    c(s_m = mean(samp), s_sd = sd(samp))
}

.rslurm_params <- readRDS('params.RDS')
.rslurm_id <- as.numeric(Sys.getenv('SLURM_ARRAY_TASK_ID'))
.rslurm_istart <- .rslurm_id * 5 + 1
.rslurm_iend <- min((.rslurm_id + 1) * 5, nrow(.rslurm_params))
.rslurm_result <- do.call(parallel::mcMap, c(.rslurm_func,
    .rslurm_params[.rslurm_istart:.rslurm_iend, , drop = FALSE],
    mc.cores = 1))
               
saveRDS(.rslurm_result, file = paste0('results_', .rslurm_id, '.RDS'))
