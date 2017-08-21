#' Introduction to the \code{rslurm} Package
#' 
#' Send long-running or parallel jobs to a Slurm workload manager (i.e. cluster)
#' using the \code{\link{slurm_call}} or \code{\link{slurm_apply}} functions.
#' 
#' @section Job submission:
#'   
#'   This package includes two core functions used to send computations to a 
#'   Slurm cluster. While \code{\link{slurm_call}} executes a function using a 
#'   single set of parameters (passed as a list), \code{\link{slurm_apply}} 
#'   evaluates the function in parallel for multiple sets of parameters grouped 
#'   in a data frame. \code{slurm_apply} automatically splits the parameter sets
#'   into equal-size chunks, each chunk to be processed by a separate cluster 
#'   node. It uses functions from the \code{\link[parallel]{parallel}} package 
#'   to parallelize computations within each node.
#'   
#'   The output of \code{slurm_apply} or \code{slurm_call} is a \code{slurm_job}
#'   object that serves as an input to the other functions in the package: 
#'   \code{\link{print_job_status}}, \code{\link{cancel_slurm}}, 
#'   \code{\link{get_slurm_out}} and \code{\link{cleanup_files}}.
#'   
#' @section Function specification:
#'   
#'   To be compatible with \code{\link{slurm_apply}}, a function may accept any 
#'   number of single value parameters. The names of these parameters must match
#'   the column names of the \code{params} data frame supplied. There are no 
#'   restrictions on the types of parameters passed as a list to 
#'   \code{\link{slurm_call}}.
#'   
#'   If the function passed to \code{slurm_call} or \code{slurm_apply} requires 
#'   knowledge of any R objects (data, custom helper functions) besides 
#'   \code{params}, a character vector corresponding to their names should be 
#'   passed to the optional \code{add_objects} argument.
#'   
#'   When parallelizing a function, since any error will interrupt all 
#'   calculations for the current node, it may be useful to wrap expressions 
#'   which may generate errors into a \code{\link[base]{try}} or 
#'   \code{\link[base]{tryCatch}} function. This will ensure the computation 
#'   continues with the next parameter set after reporting the error.
#'   
#' @section Output Format:
#'   
#'   The default output format for \code{get_slurm_out} (\code{outtype = "raw"})
#'   is a list where each element is the return value of one function call. If 
#'   the function passed to \code{slurm_apply} produces a vector output, you may
#'   use \code{outtype = "table"} to collect the output in a single data frame, 
#'   with one row by function call.
#'   
#' @examples
#' 
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
#' res <- get_slurm_out(sjob1, "table")
#' all.equal(pars, res) # Confirm correct output
#' cleanup_files(sjob1)
#' }
#'   
#' @importFrom utils capture.output
#' @docType package
#' @name rslurm-package
#'   
NULL
