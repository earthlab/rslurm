#!/bin/bash
#
#SBATCH --array=0-1
#SBATCH --job-name=test1
#SBATCH --output=slurm_%a.out
/uufs/chpc.utah.edu/sys/installdir/R/3.2.3i_rh7/lib64/R/bin/Rscript --vanilla slurm_run.R
