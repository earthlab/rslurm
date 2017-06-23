for (i in 1:2 - 1) {
Sys.setenv(SLURM_ARRAY_TASK_ID = i)
source('slurm_run.R')
}
