#' Cancels a scheduled Slurm job
#'
#' This function cancels the specified Slurm job by invoking the Slurm 
#' \code{scancel} command. It does \emph{not} delete the temporary files 
#' (e.g. scripts) created by \code{\link{slurm_apply}} or 
#' \code{\link{slurm_call}}. Use \code{\link{cleanup_files}} to remove those 
#' files. 
#' 
#' @param slr_job A \code{slurm_job} object.
#' @seealso \code{\link{cleanup_files}}
#' @export
cancel_slurm <- function(slr_job) {
    if (!(class(slr_job) == "slurm_job")) stop("input must be a slurm_job")
    system(paste("scancel -n", slr_job$jobname))
}


#' Deletes temporary files associated with a Slurm job 
#'
#' This function deletes all temporary files associated with the specified Slurm
#' job, including files created by \code{\link{slurm_apply}} or 
#' \code{\link{slurm_call}}, as well as outputs from the cluster. These files
#' should be located in the \emph{_rslurm_[jobname]} folder of the current
#' working directory.
#' 
#' @param slr_job A \code{slurm_job} object.
#' @param wait Specify whether to block until \code{slr_job} completes.
#' @examples 
#' \dontrun{
#' sjob <- slurm_apply(func, pars)
#' print_job_status(sjob) # Prints console/error output once job is completed.
#' func_result <- get_slurm_out(sjob, "table") # Loads output data into R.
#' cleanup_files(sjob)
#' }
#' @seealso \code{\link{slurm_apply}}, \code{\link{slurm_call}}
#' @export
cleanup_files <- function(slr_job, wait = TRUE) {
    if (!(class(slr_job) == "slurm_job")) stop("input must be a slurm_job")
    if (wait) wait_for_job(slr_job)
    tmpdir <- paste0("_rslurm_", slr_job$jobname)
    if (!(tmpdir %in% dir())) stop(paste("folder", tmpdir, "not found"))
    unlink(tmpdir, recursive = TRUE)
}
