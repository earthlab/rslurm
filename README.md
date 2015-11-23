
# Purpose #

This R package simplifies the process of splitting a R calculation over the SESYNC SLURM cluster. 

Currently, it is possible to use existing R packages like `parallel` to split a calculation over the 8 CPUs in a single cluster node. The functions in this package automate the process of dividing the parameter sets over multiple cluster nodes (using a slurm array), applying the function in parallel in each node using `parallel`, and recombining the output.

## Change log ##

2015-11-23 (v. 0.2.0): 

- Changed the `slurm_apply` function to use `parallel::mcMap` instead of `mcmapply`, which fixes a bug where list outputs (i.e. each function call returns a list) would be collapsed in a single list (rather than returned as a list of lists).

- Changed the interface so that the output type (table or raw) is now a parameter in `get_slurm_out` rather than in `slurm_apply`, and defaults to `raw`.

## R packages dependencies ##

- `stringr` (`word` function)
- `parallel` (`mcmapply` function)

## How to install / use ##

*Note*: This package must be installed and run from a SESYNC RStudio server account to access the SLURM cluster.

Install the package from GitHub using the following code:
```R
install.packages("devtools")
devtools::install_github("SESYNC-ci/rslurm")
```

Here's an overview of the workflow using this package:

- Create a function that you want to call with multiple parameter sets, and a data frame containing these parameter sets. 
- (optional) Save any additional R objects (data, helper functions) that are required for the main function in a RData file (using the base R function `save`).
- Call `slurm_apply` with the function, the parameters data frame and (if applicable) the additional data file as arguments. The function returns a `slurm_job` object.
- The `slurm_job` object can be passed to other utility functions in the package to inquire about the SLURM job's status (`print_job_status`), cancel the job (`cancel_slurm`), collect the output in a single list or data frame (`get_slurm_out`), or delete the temporary files generated during the process (`cleanup_files`).

Read the `rslurm-package` help file in R and each function's help file for more details.

## Potential improvements ##

* Users may want to wrap their parallelized function in a error handler (i.e. `tryCatch`) to (1) prevent a single bad case to stop the calculation and (2) report the parameter values that caused the error. Adding a function that automatically does that would be useful.

