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
#' of parameters ('slr####_[node_id].out' or 'slr####_[node_id].RData'
#' depending on output type) and those containing any console or
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
#'   calling \code{f}.
#' @param pkgs A character vector containing the names of packages that must
#'   be loaded on each cluster node. By default, it includes all packages
#'   loaded by the user when \code{slurm_apply} is called. 
#' @param output The output type. If \code{output = 'table'} (default), the 
#'   output of each node is coerced to a data frame and written with
#'   \code{\link[utils]{write.table}}. If \code{f} returns a R object that
#'   cannot be coerced to a data frame, use \code{output = 'raw'}, which will
#'   \code{\link[base]{save}} each node's output in .RData format.
#' @return A \code{slurm_job} object containing the \code{file_prefix} assigned
#'   to temporary files created by \code{slurm_apply}, a \code{job_id} assigned
#'   by the SLURM cluster, the number of \code{nodes} effectively used and the
#'   type of \code{output} returned.
#' @seealso \code{\link{slurm_call}} to evaluate a single function call.
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
slurm_apply <- function(f, params, cpus_per_node = 8, nodes = 16, data_file = NULL, 
                        pkgs = rev(.packages()), output = 'table') {
  
  # Set number of CPUs per node in cluster
  # cpus_per_node <- 8
  # Valid values for 'output' argument
  output_vals <- c('table', 'raw')
  
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
  if (!(output %in% output_vals)) {
    stop(paste('output should be one of:', paste(output_vals, collapse = ', ')))
  }
  
  # Generate an ID for temporary files
  f_id <- paste0('slr', as.integer(Sys.time()) %% 10000)
  
  .rslurm_params <- params
  save(.rslurm_params, file = paste0(f_id, '.RData'))
  
  # Get chunk size (nb. of param. sets by node)
  # Special case if less param. sets than CPUs in cluster
  if (nrow(params) < cpus_per_node * nodes) {
    nchunk <- cpus_per_node
  } else {
    nchunk <- ceiling(nrow(params) / nodes)
  }
  # Readjust number of nodes (only matters for small sets)
  nodes <- ceiling(nrow(params) / nchunk)
  
  # Create a temporary R script to run function in parallel on each node
  capture.output({
    cat(paste0(".tmplib <- lapply(c('", paste(pkgs, collapse = "','"), "'), \n",
               "           library, character.only = TRUE, quietly = TRUE) \n"))
    if(!is.null(data_file)) cat(paste0("load('", data_file, "') \n"))
    cat(paste0("load('", f_id, ".RData') \n",
               ".rslurm_id <- as.numeric(Sys.getenv('SLURM_ARRAY_TASK_ID')) \n",
               ".rslurm_istart <- .rslurm_id * ", nchunk, " + 1 \n",
               ".rslurm_iend <- min((.rslurm_id + 1) * ", nchunk, ", \n",
               "                    nrow(.rslurm_params)) \n",
               ".rslurm_result <- do.call(parallel::mcmapply, c(")) 
    print(f) 
    cat(paste0(", .rslurm_params[.rslurm_istart:.rslurm_iend, , drop = FALSE], ", 
               "mc.cores = ", cpus_per_node, ")) \n"))
    if(output == 'table') {
      cat(paste0("if (is.null(dim(.rslurm_result))) { \n",
                 "  .rslurm_result <- as.data.frame(.rslurm_result) \n",
                 "} else { \n",
                 "  .rslurm_result <- as.data.frame(t(.rslurm_result)) \n",
                 "} \n",
                 "write.table(.rslurm_result, paste0('", f_id, "_', .rslurm_id, '.out'))"))
    } else { # output == 'raw'
      cat(paste0("save(.rslurm_result, file = paste0('", f_id, "_', .rslurm_id, '.RData'))"))
    }
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
  slurm_job(f_id, job_id, nodes, output)
}
