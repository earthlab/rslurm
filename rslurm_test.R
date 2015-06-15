
# Create a data frame of mean/sd values for normal distributions 
pars <- data.frame(moy = seq(-10, 10, length.out = 1000), 
                   et = seq(0.1, 10, length.out = 1000))

# Create a function to parallelize
# ... each call takes about 1.5 sec on RStudio server  
ftest <- function(moy, et) {
  samp <- rnorm(10^7, moy, et)
  c(ms = mean(samp), ets = sd(samp))
}

# Test rslurm
sjob1 <- slurm_apply(ftest, pars)
# slurm_cancel(sjob1)
print_job_status(sjob1)
res <- get_slurm_out(sjob1)
all.equal(pars, res) # Confirm correct output
cleanup_files(sjob1)
