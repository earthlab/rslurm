#' Parallel execution of a function on the SLURM cluster
#'
#' Use \code{slurm_apply} to calculate a function over multiple sets of 
#' parameters in parallel, using up to 16 nodes of the SLURM cluster. 
#' 
#' This function creates temporary files for the parameters data ('slr####.RData'),
#' the R script sent to each node ('slr####.R') and the Bash script 
#' ('slr####.sh') that launches the parallel computation. The set of input 
#' parameters is divided in chunks sent to each node, and \code{f} is evaluated
#' in parallel within each node using functions from the \code{parallel} R
#' package. 
#' 
#' Any other R objects (besides \code{params}) that \code{f} needs to access
#' should be saved in a .RData file (using \code{\link[base]{save}}) and the
#' name of this file should be given as the optional \code{data_file} argument.
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
#' @param data_file The name of a R data file (created with 
#'   \code{\link[base]{save}}) that will be loaded on each node prior to
#'   calling \code{f}. Note that objects in this file \emph{cannot} share one
#'   of the following names: params, a_id, iend, istart, result.
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
slurm_apply <- function(f, params, nodes = 16, data_file = NULL) {
  
  # Set number of CPUs per node in cluster
  cpus_per_node <- 8
  # Names 'reserved' by slurm_apply
  rsvd_names <- c('params', 'a_id', 'istart', 'iend', 'result')
  
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
  
  # Ensure that data_file, if present, contains no conflicting names
  if (!is.null(data_file)) {
    tmpEnv <- new.env()
    dnames <- load(data_file, envir = tmpEnv)
    if (any(rsvd_names %in% dnames)) {
      rm(tmpEnv, dnames)
      stop(paste('No data_file objects may have one the following names:',
                 paste(rsvd_names, collapse = ', ')))
    }
    rm(tmpEnv, dnames)
  }
  
  # Generate an ID for temporary files
  f_id <- paste0('slr', as.integer(Sys.time()) %% 10000)
  
  save(params, file = paste0(f_id, '.RData'))
  
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
    if(!is.null(data_file)) cat(paste0("load('", data_file, "') \n"))
    cat(paste0("load('", f_id, ".RData') \n",
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