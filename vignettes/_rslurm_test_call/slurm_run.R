.tmplib <- lapply(c('base','methods','datasets','utils','grDevices','graphics','stats','rslurm','devtools'), 
                  library, character.only = TRUE, quietly = TRUE)
.rslurm_func <- function(par_mu, par_sd) {
    samp <- rnorm(10^6, par_mu, par_sd)
    c(s_mu = mean(samp), s_sd = sd(samp))
}

.rslurm_params <- readRDS('params.RDS')
.rslurm_result <- do.call(.rslurm_func, .rslurm_params)
               
saveRDS(.rslurm_result, file = 'results_0.RDS')
