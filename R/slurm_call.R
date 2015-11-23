#' Execution of a single function call on the SLURM cluster
#'
#' Use \code{slurm_call} to perform a single function evaluation on the SLURM cluster. 
#' 
#' This function creates temporary files for the parameters data ("slr####.RData"),
#' the R script evaluating the function ("slr####.R") and the Bash script 
#' ("slr####.sh") that sends the batch run command to the cluster.
#' 
#' Any other R objects (besides \code{params}) that \code{f} needs to access
#' should be saved in a .RData file (using \code{\link[base]{save}}) and the
#' name of this file should be given as the optional \code{data_file} argument.
#' 
#' When processing the computation job, the SLURM cluster will output two files:
#' one .RData file containing the function output ("slr####_0.RData") and one 
#' containing any console or error output produced by R ("slurm-[job_id].out").
#' 
#' After sending the job to the SLURM cluster, \code{slurm_call} returns a
#' \code{slurm_job} object which can be used to cancel the job, get the job 
#' status or output, and delete the temporary files associated with it. See 
#' the description of the related functions for more details.  
#'  
#' @param f Any R function.
#' @param params A named list of parameters to pass to \code{f}.
#' @param data_file The name of a R data file (created with 
#'   \code{\link[base]{save}}) to be loaded prior to calling \code{f}.
#' @param pkgs A character vector containing the names of packages that must
#'   be loaded on each cluster node. By default, it includes all packages
#'   loaded by the user when \code{slurm_call} is called. 
#' @return A \code{slurm_job} object containing the \code{file_prefix} assigned
#'   to temporary files created by \code{slurm_call}, a \code{job_id} assigned
#'   by the SLURM cluster and the number of \code{nodes} used (always 1 for
#'   \code{slurm_call}).
#' @seealso \code{\link{slurm_apply}} to parallelize a function over a parameter set.
#' @seealso \code{\link{cancel_slurm}}, \code{\link{cleanup_files}}, 
#'   \code{\link{get_slurm_out}} and \code{\link{print_job_status}} 
#'   which use the output of this function. 
#' @export    
slurm_call <- function(f, params, data_file = NULL, pkgs = rev(.packages())) {
    
    # Check inputs
    if (!is.function(f)) {
        stop("first argument to slurm_call should be a function")
    }
    if (!is.list(params)) {
        stop("second argument to slurm_call should be a list")
    }
    if (is.null(names(params)) || !(names(params) %in% names(formals(f)))) {
        stop("names of params must match arguments of f")
    }
    
    # Generate an ID for temporary files
    f_id <- paste0("slr", as.integer(Sys.time()) %% 10000)
    
    .rslurm_params <- params
    save(.rslurm_params, file = paste0(f_id, ".RData"))
    
    # Create a temporary R script to run function on SLURM cluster
    capture.output({
        cat(paste0(".tmplib <- lapply(c('", paste(pkgs, collapse = "','"), "'), \n",
                   "           library, character.only = TRUE, quietly = TRUE) \n"))
        if(!is.null(data_file)) cat(paste0("load('", data_file, "') \n"))
        cat(paste0("load('", f_id, ".RData') \n",
                   ".rslurm_result <- do.call(")) 
        print(f) 
        cat(paste0(", .rslurm_params) \n",
                   "save(.rslurm_result, file = paste0('", f_id, "_0.RData'))"))
    }, file = paste0(f_id, ".R"))
    
    # Create temporary bash script
    capture.output(
        cat(paste0("#!/bin/bash \n",
                   "# \n",
                   "#SBATCH -n1 \n",
                   "Rscript --vanilla ", f_id, ".R")), 
        file = paste0(f_id, ".sh"))
    
    # Send job to slurm and capture job_id
    sbatch_ret <- system(paste0("sbatch ", f_id, ".sh"), intern = TRUE)
    job_id <- stringr::word(sbatch_ret, -1)
    
    # Return 'slurm_job' object
    slurm_job(f_id, job_id, nodes = 1)
}