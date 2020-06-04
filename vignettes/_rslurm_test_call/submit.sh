#!/bin/bash
#
#SBATCH --ntasks=1
#SBATCH --job-name=test_call
#SBATCH --output=slurm_0.out
/usr/lib/R/bin/Rscript --vanilla slurm_run.R
