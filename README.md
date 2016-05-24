rslurm
======

This R package simplifies the process of splitting a R calculation over the SESYNC SLURM cluster. 

Currently, it is possible to use existing R packages like `parallel` to split a calculation over the 8 CPUs in a single cluster node. The functions in this package automate the process of dividing the parameter sets over multiple cluster nodes (using a slurm array), applying the function in parallel in each node using `parallel`, and recombining the output.

How to install / use
--------------------

*Note*: This package must be installed and run from a SESYNC RStudio server account to access the SLURM cluster.

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

