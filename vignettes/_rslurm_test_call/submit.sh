#!/bin/bash
#
#SBATCH --ntasks=1
#SBATCH --job-name=test_call
#SBATCH --output=slurm_0.out
C:/PROGRA~1/R/R-36~1.0/bin/x64/Rscript --vanilla slurm_run.R
