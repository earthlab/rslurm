#' rslurm: Simple parallel calculations using the SLURM cluster
#'
#' This package automates the process of splitting a R calculation over the 
#' SESYNC SLURM cluster. 
#' 
#' @section Overview:
#' The core function in the package is \code{\link{slurm_apply}}, with two 
#' essential arguments: a function \code{f} and a data frame of parameters 
#' \code{params} to apply the function too. It automatically splits the set of
#' parameters into equal-size chunks, each chunk to be processed by a separate
#' cluster node. It uses functions from the \code{\link[parallel]{parallel}}
#' package to parallelize computations within each node.
#' 
#' The output of \code{\link{slurm_apply}} is a \code{slurm_job} object that
#' serves as an input to the other functions in the package: 
#' \code{\link{print_job_status}}, \code{\link{cancel_slurm}}, 
#' \code{\link{get_slurm_out}} and \code{\link{cleanup_files}}.
#' 
#' For bug reports or questions about this package, contact 
#' Philippe Marchand (pmarchand@@sesync.org).
#' 
#' @section Function Specification:
#' To be compatible with \code{\link{slurm_apply}}, a function may accept
#' any number of single value parameters. The names of these parameters must 
#' match the column names of the \code{params} data frame supplied. It may 
#' return a single value or a vector. 
#' 
#' Note that none of the packages or data loaded into your current environment
#' will be sent to the cluster. Therefore, the function should be written to
#' load any data it will need and to prefix external functions with their 
#' package name i.e. \code{pkg_name::func_name}.
#' 
#' Since any error will interrupt all calculations for the current node, it may
#' be useful to wrap expressions which may generate errors into a
#' \code{\link[base]{try}} or \code{\link[base]{tryCatch}} function. This will
#' ensure the computation continues with the next parameter set after reporting
#' the error. 
#' 
#' @examples
#' \dontrun{
#' # Create a data frame of mean/sd values for normal distributions 
#' pars <- data.frame(par_m = seq(-10, 10, length.out = 1000), 
#'                    par_sd = seq(0.1, 10, length.out = 1000))
#'                    
#' # Create a function to parallelize
#' ftest <- function(par_m, par_sd) {
#'  samp <- rnorm(10^7, par_m, par_sd)
#'  c(s_m = mean(samp), s_sd = sd(samp))
#' }
#'
#' sjob1 <- slurm_apply(ftest, pars)
#' print_job_status(sjob1)
#' res <- get_slurm_out(sjob1)
#' all.equal(pars, res) # Confirm correct output
# 'cleanup_files(sjob1)
#' }
#' 
#' @docType package
#' @name rslurm
NULL


#' Parallel execution of a function on the SLURM cluster
#'
#' Use \code{slurm_apply} to calculate a function over multiple sets of 
#' parameters in parallel, using up to 16 nodes of the SLURM cluster. 
#' 
#' This function creates temporary files for the parameters data ('slr####.dat'),
#' the R script sent to each node ('slr####.dat') and the Bash script 
#' ('slr####.sh') that launches the parallel computation. The set of input 
#' parameters is divided in chunks sent to each node, and \code{f} is evaluated
#' in parallel within each node using functions from the \code{parallel} R
#' package. 
#' 
#' When processing the computation job, the SLURM cluster will output two types
#' of files: those containing the return values of the function for each subset
#' of parameters ('slr####_[node_id].out') and those containing any console or
#' error output produced by R on each node ('slurm-[job_id]_[node_id].out').
#' 
#' After sending the job to the SLURM cluster, \code{slurm_apply} returns a
#' \code{slurm_job} object which can be used to cancel the job, get the job 
#' status or output, and delete the temporary files associated with it. See 
#' the description of the related functions for more details.  
#'  
#' @param f A function that accepts one or many single values as parameters and
#'   returns a single value or a vector.
#' @param params A data frame of parameter values to apply \code{f} to. Each
#'   column corresponds to a parameter of \code{f} (\emph{Note}: names must 
#'   match) and each row corresponds to a separate function call.
#' @param nodes The (maximum) number of cluster nodes to spread the calculation
#'   over. \code{slurm_apply} automatically divides \code{params} in chunks of
#'   approximately equal size to send to each node. Less nodes are allocated if 
#'   the parameter set is too small to use all CPUs in the requested nodes.
#' @return A \code{slurm_job} object containing the \code{file_prefix} assigned
#'   to temporary files created by \code{slurm_apply}, a \code{job_id} assigned
#'   by the SLURM cluster and the number of \code{nodes} effectively used.
#' @seealso \code{\link{cancel_slurm}}, \code{\link{cleanup_files}}, 
#'   \code{\link{get_slurm_out}} and \code{\link{print_job_status}} 
#'   which use the output of this function.    
#' @examples
#' \dontrun{
#' sjob <- slurm_apply(func, pars)
#' print_job_status(sjob) # Prints console/error output once job is completed.
#' func_result <- get_slurm_out(sjob) # Loads output data into R.
#' cleanup_files(sjob)
#' }
#' @export       
slurm_apply <- function(f, params, nodes = 16) {
  
  # Set number of CPUs per node in cluster
  cpus_per_node <- 8
  
  # Check inputs
  if (!is.function(f)) {
    stop('first argument to slurm_apply should be a function')
  }
  if (!is.data.frame(params)) {
    stop('second argument to slurm_apply should be a data.frame')
  }
  if (is.null(names(params)) || !(names(params) %in% names(formals(f)))) {
    stop('column names of params must match arguments of f')
  }
  
  # Generate an ID for temporary files
  f_id <- paste0('slr', as.integer(Sys.time()) %% 10000)
  
  write.table(params, file = paste0(f_id, '.dat'))
  
  # Get chunk size (nb. of param. sets by node)
  # Special case if less param. sets than CPUs in cluster (reduce # of nodes)
  if (nrow(params) < cpus_per_node * nodes) {
    nchunk <- cpus_per_node
    nodes <- ceiling(nrow(params) / nchunk)
  } else {
    nchunk <- ceiling(nrow(params) / nodes)
  }
  
  # Create a temporary R script to run function in parallel on each node
  capture.output({
    cat(paste0("params <- read.table('", f_id, ".dat') \n",
               "a_id <- as.numeric(Sys.getenv('SLURM_ARRAY_TASK_ID')) \n",
               "istart <- a_id * ", nchunk, " + 1 \n",
               "iend <- min((a_id + 1) * ", nchunk, ", nrow(params)) \n",
               "result <- do.call(parallel::mcmapply, c(")) 
    print(f) 
    cat(paste0(", params[istart:iend, , drop = FALSE], ", 
               "mc.cores = ", cpus_per_node, ")) \n", 
               "if (is.null(dim(result))) { \n",
               "  result <- as.data.frame(result) \n",
               "} else { \n",
               "  result <- as.data.frame(t(result)) \n",
               "} \n",
               "write.table(result, paste0('", f_id, "_', a_id, '.out'))"))
  }, file = paste0(f_id, '.R'))
  
  # Create temporary bash script
  capture.output(
    cat(paste0("#!/bin/bash \n",
               "# \n",
               "#SBATCH --array=0-", nodes - 1, " \n",
               "Rscript --vanilla ", f_id, ".R")), 
    file = paste0(f_id, '.sh'))
  
  # Send job to slurm and capture job_id
  sbatch_ret <- system(paste0('sbatch ', f_id, '.sh'), intern = TRUE)
  job_id <- stringr::word(sbatch_ret, -1)
  
  # Return 'slurm_job' object with script file prefix, job_id, number of nodes
  slurm_job(f_id, job_id, nodes)
}


# Constructor for slurm_job class
slurm_job <- function(file_prefix, job_id, nodes) {
  slr_job <- list(file_prefix = file_prefix, job_id = job_id, nodes = nodes)
  class(slr_job) <- 'slurm_job'
  slr_job
}


#' Cancels a scheduled SLURM job
#'
#' This function cancels the specified SLURM job by invoking the SLURM 
#' \code{scancel} command. It does \emph{not} delete the temporary files 
#' (e.g. scripts) created by \code{\link{slurm_apply}}. 
#' Use \code{\link{cleanup_files}} to remove those files. 
#' 
#' @param slr_job A \code{slurm_job} object output by \code{\link{slurm_apply}}.
#' @seealso \code{\link{slurm_apply}}, \code{\link{cleanup_files}}
#' @export
cancel_slurm <- function(slr_job) {
  if (!(class(slr_job) == 'slurm_job')) stop('input must be a slurm_job')
  system(paste('scancel', slr_job$job_id))
}


#' Prints the status of a SLURM job and, if completed, its console/error output
#'
#' Prints the status of a SLURM job and, if completed, its console/error output.
#'
#' If the specified SLURM job is still in the queue or running, this function
#' prints its current status (as output by the SLURM \code{squeue} command).
#' The output displays one row by node currently running part of the job ('R' in
#' the 'ST' column) and how long it has been running ('TIME'). One row indicates
#' the portions of the job still in queue ('PD' in the 'ST' column), if any. 
#' 
#' If all portions of the job have completed or stopped, the function prints the 
#' console and error output, if any, generated by each node.
#' 
#' @param slr_job A \code{slurm_job} object output by \code{\link{slurm_apply}}.
#' @seealso \code{\link{slurm_apply}}
#' @export
print_job_status <- function(slr_job) {
  if (!(class(slr_job) == 'slurm_job')) stop('input must be a slurm_job')  
  stat <- suppressWarnings(system2('squeue', args = paste('-j', slr_job$job_id), 
                                   stdout = TRUE, stderr = TRUE))
  if (length(stat) > 1) {
    print(c('Job running or in queue. Status:', stat))
  } else {
    print('Job completed or stopped. Printing console output below if any.')
    out_files <- paste0('slurm-', slr_job$job_id, '_', 
                        0:(slr_job$nodes - 1), '.out')
    slurm_out <- suppressWarnings(
      lapply(out_files, function(x) paste(readLines(x), sep = '\n')))
    for (s in slurm_out) {
      if (length(s) > 0) print(s)
    } 
  }
}  


#' Reads the output of a function calculated on the SLURM cluster 
#'
#' This function reads all function output files (one by cluster node used) from 
#' the specified SLURM job and returns the result in a single data frame. It 
#' doesn't record any messages (including warnings or errors) output to the R
#' console during the computation; these can be consulted by invoking 
#' \code{\link{print_job_status}}.
#' 
#' @param slr_job A \code{slurm_job} object output by \code{\link{slurm_apply}}.
#' @return A data frame with one column by return value of the function passed
#'   to \code{\link{slurm_apply}}, where each row is the output of the 
#'   corresponding row in the params data frame passed to 
#'   \code{\link{slurm_apply}}.
#' @seealso \code{\link{slurm_apply}}, \code{\link{print_job_status}}
#' @export
get_slurm_out <- function(slr_job) {
  # Import and combine output files from slurm_job slr_job
  # Output: data frame with one function output by row
  if (!(class(slr_job) == 'slurm_job')) stop('input must be a slurm_job')
  out_files <- paste0(slr_job$file_prefix, '_', 0:(slr_job$nodes - 1), '.out')
  slurm_out <- do.call(rbind, lapply(out_files, read.table))
  rownames(slurm_out) <- NULL
  slurm_out
}


#' Deletes temporary files associated with a SLURM job 
#'
#' This function deletes all temporary files associated with the specified SLURM
#' job, including files created by \code{\link{slurm_apply}} (parameters data, R
#' and Bash scripts, all starting with 'slr####'), function output files
#' ('slr####_[node_id].out') as well as the console and error output files
#' (starting with 'slurm-[job_id]').
#' 
#' @param slr_job A \code{slurm_job} object output by \code{\link{slurm_apply}}.
#' @examples 
#' \dontrun{
#' sjob <- slurm_apply(func, pars)
#' print_job_status(sjob) # Prints console/error output once job is completed.
#' func_result <- get_slurm_out(sjob) # Loads output data into R.
#' cleanup_files(sjob)
#' }
#' @seealso \code{\link{slurm_apply}}, \code{\link{print_job_status}},
#'   \code{\link{get_slurm_out}}
#' @export
cleanup_files <- function(slr_job) {
  if (!(class(slr_job) == 'slurm_job')) stop('input must be a slurm_job')  
  unlink(paste0(slr_job$file_prefix, '*'))
  unlink(paste0('slurm-', slr_job$job_id, '_', 0:(slr_job$nodes - 1), '.out'))
}