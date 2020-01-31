#' Execute a Slurm job locally
#' 
#' Run a previously created \code{slurm_job} object locally instead of on a
#' Slurm cluster
#' 
#' This function is most useful for testing your function on a reduced dataset
#' before submitting the full job to the Slurm cluster.
#' 
#' Call \code{local_slurm_array} on a \code{slurm_job} object created with
#' \code{slurm_apply(..., submit = FALSE)} or \code{slurm_map(..., submit = FALSE)}.
#' The job will run serially on the local system rather than being submitted
#' to the Slurm cluster. 
#' 
#' @param slr_job An object of class \code{slurm_job}.
#' @param rscript_path The location of the Rscript command. If not specified, 
#'   defaults to the location of Rscript within the R installation being run.
#'  
#' @examples
#' \dontrun{
#' sjob <- slurm_apply(func, pars, submit = FALSE)
#' local_slurm_array(sjob)
#' func_result <- get_slurm_out(sjob, "table") # Loads output data into R.
#' cleanup_files(sjob)
#' }
#' @export
local_slurm_array <- function(slr_job, rscript_path = NULL) {
    # Check that input is a slurm_job
    if (!inherits(slr_job, 'slurm_job')) {
        stop("argument of local_slurm_array should be a slurm_job")
    }
    
    if (is.null(rscript_path)) {
        rscript_path <- file.path(R.home("bin"), "Rscript")
    }
    
    slurm_run_path <- paste0("_rslurm_", slr_job$jobname)
    
    # Execute each array task locally and sequentially
    for (i in 1:slr_job$nodes - 1) {
        system(paste0('cd ', slurm_run_path, ' && SLURM_ARRAY_TASK_ID=', i, ' ', rscript_path, ' --vanilla slurm_run.R'))
    }
    
    return(slr_job)
}
