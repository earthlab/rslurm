#' Execution of a single function call on the Slurm cluster
#' 
#' Use \code{slurm_call} to perform a single function evaluation a the Slurm 
#' cluster.
#' 
#' This function creates a temporary folder ("_rslurm_[jobname]") in the current
#' directory, holding .RData and .RDS data files, the R script to run and the
#' Bash submission script generated for the Slurm job.
#' 
#' The names of any other R objects (besides \code{params}) that \code{f} needs 
#' to access should be listed in the \code{global_objects} argument.
#' 
#' Use \code{slurm_options} to set any option recognized by \code{sbatch}, e.g. 
#' \code{slurm_options = list(time = "1:00:00", share = TRUE)}. See
#' \url{http://slurm.schedmd.com/sbatch.html} for details on possible options. 
#' Note that full names must be used (e.g. "time" rather than "t") and that
#' flags (such as "share") must be specified as TRUE. The "job-name", "ntasks" 
#' and "output" options are already determined by \code{slurm_call} and should 
#' not be manually set.
#' 
#' When processing the computation job, the Slurm cluster will output two files 
#' in the temporary folder: one with the return value of the function 
#' ("results_0.RDS") and one containing any console or error output produced by
#' R ("slurm_[node_id].out").
#' 
#' If \code{submit = TRUE}, the job is sent to the cluster and a confirmation 
#' message (or error) is output to the console. If \code{submit = FALSE}, a
#' message indicates the location of the saved data and script files; the job
#' can be submitted manually by running the shell command \code{sbatch
#' submit.sh} from that directory.
#' 
#' After sending the job to the Slurm cluster, \code{slurm_call} returns a 
#' \code{slurm_job} object which can be used to cancel the job, get the job 
#' status or output, and delete the temporary files associated with it. See the
#' description of the related functions for more details.
#' 
#' @param f Any R function.
#' @param params A named list of parameters to pass to \code{f}.
#' @param jobname The name of the Slurm job; if \code{NA}, it is assigned a 
#'   random name of the form "slr####".
#' @param global_objects A character vector containing the name of R objects to be 
#'   saved in a .RData file and loaded on each cluster node prior to calling 
#'   \code{f}.
#' @param add_objects Older deprecated name of \code{global_objects}, retained for
#' backwards compatibility.
#' @param pkgs A character vector containing the names of packages that must be
#'   loaded on each cluster node. By default, it includes all packages loaded by
#'   the user when \code{slurm_call} is called.
#' @param libPaths A character vector describing the location of additional R
#'   library trees to search through, or NULL. The default value of NULL
#'   corresponds to libraries returned by \code{.libPaths()} on a cluster node.
#'   Non-existent library trees are silently ignored.
#' @param rscript_path The location of the Rscript command. If not specified, 
#'   defaults to the location of Rscript within the R installation being run.
#' @param r_template The path to the template file for the R script run on each node. 
#'   If NULL, uses the default template "rslurm/templates/slurm_run_single_R.txt".
#' @param sh_template The path to the template file for the sbatch submission script. 
#'   If NULL, uses the default template "rslurm/templates/submit_single_sh.txt".
#' @param slurm_options A named list of options recognized by \code{sbatch}; see
#'   Details below for more information.
#' @param submit Whether or not to submit the job to the cluster with 
#'   \code{sbatch}; see Details below for more information.
#' @return A \code{slurm_job} object containing the \code{jobname} and the number
#'   of \code{nodes} effectively used.
#' @seealso \code{\link{slurm_apply}} to parallelize a function over a parameter
#'   set.
#' @seealso \code{\link{cancel_slurm}}, \code{\link{cleanup_files}}, 
#'   \code{\link{get_slurm_out}} and \code{\link{get_job_status}} which use
#'   the output of this function.
#' @export
slurm_call <- function(f, params = list(), jobname = NA, global_objects = NULL, add_objects = NULL, 
                       pkgs = rev(.packages()), libPaths = NULL, rscript_path = NULL,
                       r_template = NULL, sh_template = NULL, slurm_options = list(), 
                       submit = TRUE) {
    # Check inputs
    if (!is.function(f)) {
        stop("first argument to slurm_call should be a function")
    }
    if (!missing(params)) {
        if (!is.list(params)) {
            stop("second argument to slurm_call should be a list")
        }
        if (is.null(names(params)) || (!is.primitive(f) && !"..." %in% names(formals(f)) && any(!names(params) %in% names(formals(f))))) {
            stop("names of params must match arguments of f")
        }
    } 
    
    # Check for use of deprecated argument
    if (!missing("add_objects")) {
        warning("Argument add_objects is deprecated; use global_objects instead.", .call = FALSE)
        global_objects <- add_objects
    }
    
    # Default templates
    if(is.null(r_template)) {
        r_template <- system.file("templates/slurm_run_single_R.txt", package = "rslurm")
    }
    if(is.null(sh_template)) {
        sh_template <- system.file("templates/submit_single_sh.txt", package = "rslurm")
    }
        
    jobname <- make_jobname(jobname)
    
    # Create temp folder
    tmpdir <- paste0("_rslurm_", jobname)
    dir.create(tmpdir, showWarnings = FALSE)
    
    saveRDS(params, file = file.path(tmpdir, "params.RDS"))
    saveRDS(f, file = file.path(tmpdir, "f.RDS"))
    if (!is.null(global_objects)) {
        save(list = global_objects,
             file = file.path(tmpdir, "add_objects.RData"),
             envir = environment(f))
    }    
    
    # Create a R script to run function on cluster
    template_r <- readLines(r_template)
    script_r <- whisker::whisker.render(template_r,
                    list(pkgs = pkgs,
                         add_obj = !is.null(global_objects),
                         libPaths = libPaths))
    writeLines(script_r, file.path(tmpdir, "slurm_run.R"))
    
    # Create submission bash script
    template_sh <- readLines(sh_template)
    slurm_options <- format_option_list(slurm_options)
    if (is.null(rscript_path)){
        rscript_path <- file.path(R.home("bin"), "Rscript")
    }
    script_sh <- whisker::whisker.render(template_sh, 
                                         list(jobname = jobname,
                                              flags = slurm_options$flags, 
                                              options = slurm_options$options,
                                              rscript = rscript_path))
    writeLines(script_sh, file.path(tmpdir, "submit.sh"))
    
    # Submit job to Slurm if applicable
    if (submit && system('squeue', ignore.stdout = TRUE)) {
        submit <- FALSE
        cat("Cannot submit; no Slurm workload manager found\n")
    }
    if (submit) {
        jobid <- submit_slurm_job(tmpdir)
    } else {
        jobid <- NA
        cat(paste("Submission scripts output in directory", tmpdir,"\n"))
    }

    # Return 'slurm_job' object
    slurm_job(jobname, jobid, 1)
}
