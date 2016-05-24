rslurm
======

This R package simplifies the process of splitting a R calculation over a computing cluster that uses the [SLURM](http://slurm.schedmd.com/) workload manager.

Currently, it is possible to use existing R packages like `parallel` to split a calculation over multiple CPUs in a single cluster node. The functions in this package automate the process of dividing the parameter sets over multiple cluster nodes (using a slurm array), applying the function in parallel in each node using `parallel`, and recombining the output.


How to install / use
--------------------

Install the package from GitHub using the following code:
```R
install.packages("devtools")
devtools::install_github("SESYNC-ci/rslurm")
```

Here's an overview of the workflow using this package:

- Create a function that you want to call with multiple parameter sets, and a data frame containing these parameter sets. 
- Call `slurm_apply` with the function, the parameters data frame and (if applicable) the names of additional R objects needed as arguments. The function returns a `slurm_job` object.
- The `slurm_job` object can be passed to other utility functions in the package to inquire about the SLURM job's status (`print_job_status`), cancel the job (`cancel_slurm`), collect the output in a single list or data frame (`get_slurm_out`), or delete the temporary files generated during the process (`cleanup_files`).

Read the `rslurm-package` help file in R and each function's help file for more details.


SESYNC users
------------

When using this package on the SESYNC SLURM cluster, you must specify the correct partition for jobs to be run in serial or parallel mode. This can be done in one of two ways:

*As an option set in each call to the `rslurm` functions*

* For `slurm_apply`, set `slurm_options = list(partition = "sesync")`.
* For `slurm_call`, set `slurm_options = list(partition = "sesyncshared", share = TRUE)`.

*By editing the template scripts*

Note: We recommend saving a backup copy of the original templates before editing them.

* Go to the `rslurm` folder in your R library (generally located at `~/R/x86_64-pc-linux-gnu-library/3.3/`, with "3.3" replaced with the latest version of R). Open the `templates` subfolder.

* In `submit_sh.txt`, insert the line 
```
#SBATCH --partition=sesync
``` 
before the first `#SBATCH` line.

* In `submit_single_sh.txt`, insert the lines
```
#SBATCH --partition=sesyncshared
#SBATCH --share
```
before the first `#SBATCH` line.



