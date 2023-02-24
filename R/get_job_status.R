#' Get the status of a Slurm job
#'
#' This function returns the completion status of a Slurm job, its queue status 
#' if any and log outputs. 
#' 
#' The \code{queue} element of the output is a data frame matching the output
#' of the Slurm \code{squeue} command for that job; it will only indicate portions
#' of job that are running or in queue. The \code{log} element is a
#' vector of the contents of console/error output files for each node where the 
#' job is running.
#' 
#' @importFrom utils read.table
#' @param slr_job A \code{slurm_job} object.
#' @return A list with three elements: \code{completed} is a logical value 
#'   indicating if all portions of the job have completed or stopped, \code{queue} 
#'   contains the information on job elements still in queue, and
#'   \code{log} contains the console/error logs. 
#' @export
get_job_status <- function(slr_job) {
    
    if (!(inherits(slr_job, "slurm_job"))) stop("input must be a slurm_job")
    
    # Get queue info
    squeue_out <- suppressWarnings(
        system(paste("squeue -n", slr_job$jobname), intern = TRUE)
    )
    queue <- read.table(text = squeue_out, header = TRUE)
    completed <- nrow(queue) == 0
    
    # Get output logs
    tmpdir <- paste0("_rslurm_", slr_job$jobname)
    out_files <- list.files(tmpdir, pattern = "slurm.*\\.out", full.names = TRUE)
    logs <- vapply(out_files, 
                   function(outf) paste(readLines(outf), collapse = "\n"),
                   "")
    
    job_status <- list(completed = completed, queue = queue, log = logs)
    class(job_status) <- "slurm_job_status"
    job_status
}  


# Format job status output
print.slurm_job_status <- function(stat) {
    if (stat$complete) {
        cat("Job completed or stopped.\n\n")
    } else {
        print(stat$queue)
        cat("\n")
    }
    
    cat("Last console output\n\n")
    shorten_log <- function(txt, lmax = 60) { # Shorten txt to lmax chars.
        l <- nchar(txt)
        ifelse(l <= lmax, txt,
               paste("...", substr(txt, l - lmax, l)))
    }
    
    for (i in seq_along(stat$log)) {
        cat(paste0(i-1, ": ", shorten_log(stat$log[[i]]), "\n"))
    }
}
