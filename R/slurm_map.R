#' Parallel execution of a function over a list on the Slurm cluster
#'
#' Use \code{slurm_map} to compute function over a list
#' in parallel, spread across multiple nodes of a Slurm cluster,
#' with similar syntax to \code{lapply}.
#'
#' This function creates a temporary folder ("_rslurm_[jobname]") in the current
#' directory, holding .RData and .RDS data files, the R script to run and the Bash
#' submission script generated for the Slurm job.
#'
#' The set of input parameters is divided in equal chunks sent to each node, and
#' \code{f} is evaluated in parallel within each node using functions from the
#' \code{parallel} R package. The names of any other R objects (besides
#' \code{x}) that \code{f} needs to access should be included in
#' \code{global_objects} or passed as additional arguments through \code{...}.
#'
#' Use \code{slurm_options} to set any option recognized by \code{sbatch}, e.g.
#' \code{slurm_options = list(time = "1:00:00", share = TRUE)}.
#' See \url{http://slurm.schedmd.com/sbatch.html} for details on possible options.
#' Note that full names must be used (e.g. "time" rather than "t") and that flags
#' (such as "share") must be specified as TRUE. The "array", "job-name", "nodes", 
#' "cpus-per-task" and "output" options are already determined by 
#' \code{slurm_map} and should not be manually set.
#'
#' When processing the computation job, the Slurm cluster will output two types
#' of files in the temporary folder: those containing the return values of the
#' function for each subset of parameters ("results_[node_id].RDS") and those
#' containing any console or error output produced by R on each node
#' ("slurm_[node_id].out").
#'
#' If \code{submit = TRUE}, the job is sent to the cluster and a confirmation
#' message (or error) is output to the console. If \code{submit = FALSE},
#' a message indicates the location of the saved data and script files; the
#' job can be submitted manually by running the shell command
#' \code{sbatch submit.sh} from that directory.
#'
#' After sending the job to the Slurm cluster, \code{slurm_map} returns a
#' \code{slurm_job} object which can be used to cancel the job, get the job
#' status or output, and delete the temporary files associated with it. See
#' the description of the related functions for more details.
#'
#' @param x A list to apply \code{f} to. Each
#'   element of \code{x} corresponds to a separate function call.
#' @param f A function that accepts one element of \code{x} as its first argument,
#' and may return any type of R object.
#' @param ... Additional arguments to \code{f}. These arguments do not vary
#' with each call to \code{f}.
#' @param jobname The name of the Slurm job; if \code{NA}, it is assigned a
#'   random name of the form "slr####".
#' @param nodes The (maximum) number of cluster nodes to spread the calculation
#'   over. \code{slurm_map} automatically divides \code{x} in chunks of
#'   approximately equal size to send to each node. Less nodes are allocated if
#'   the parameter set is too small to use all CPUs on the requested nodes.
#' @param cpus_per_node The number of CPUs requested per node. This argument is
#'   mapped to the Slurm parameter \code{cpus-per-task}.
#' @param processes_per_node The number of logical CPUs to utilize per node,
#'   i.e. how many processes to run in parallel per node. This can exceed
#'   \code{cpus_per_node} for nodes which support hyperthreading. Defaults to
#'   \code{processes_per_node = cpus_per_node}.
#' @param preschedule_cores Corresponds to the \code{mc.preschedule} argument of 
#'   \code{parallel::mclapply}. Defaults to \code{TRUE}. If \code{TRUE}, the 
#'   elements of \code{x} are assigned to cores before computation. 
#'   If \code{FALSE}, each element of \code{x} is executed by the next available core.
#'   Setting \code{FALSE} may be faster if 
#'   different elements of \code{x} result in very variable completion time for
#'   jobs.
#' @param job_array_task_limit The maximum number of job array tasks to run at 
#'   the same time. Defaults to \code{NULL} (no limit).
#' @param global_objects A character vector containing the name of R objects to be
#'   saved in a .RData file and loaded on each cluster node prior to calling
#'   \code{f}.
#' @param pkgs A character vector containing the names of packages that must
#'   be loaded on each cluster node. By default, it includes all packages
#'   loaded by the user when \code{slurm_map} is called.
#' @param libPaths A character vector describing the location of additional R
#'   library trees to search through, or NULL. The default value of NULL
#'   corresponds to libraries returned by \code{.libPaths()} on a cluster node.
#'   Non-existent library trees are silently ignored.
#' @param rscript_path The location of the Rscript command. If not specified, 
#'   defaults to the location of Rscript within the R installation being run.
#' @param r_template The path to the template file for the R script run on each node. 
#'   If NULL, uses the default template "rslurm/templates/slurm_run_R.txt".
#' @param sh_template The path to the template file for the sbatch submission script. 
#'   If NULL, uses the default template "rslurm/templates/submit_sh.txt".
#' @param slurm_options A named list of options recognized by \code{sbatch}; see
#'   Details below for more information.
#' @param submit Whether or not to submit the job to the cluster with
#'   \code{sbatch}; see Details below for more information.
#' @return A \code{slurm_job} object containing the \code{jobname} and the
#'   number of \code{nodes} effectively used.
#' @seealso \code{\link{slurm_call}} to evaluate a single function call.
#' @seealso \code{\link{slurm_apply}} to evaluate a function row-wise over a
#' data frame of parameters.
#' @seealso \code{\link{cancel_slurm}}, \code{\link{cleanup_files}},
#'   \code{\link{get_slurm_out}} and \code{\link{get_job_status}}
#'   which use the output of this function.
#' @examples
#' \dontrun{
#' sjob <- slurm_map(func, list)
#' get_job_status(sjob) # Prints console/error output once job is completed.
#' func_result <- get_slurm_out(sjob, "table") # Loads output data into R.
#' cleanup_files(sjob)
#' }
#' @export
slurm_map <- function(x, f, ..., jobname = NA, nodes = 2,
                      cpus_per_node = 2, processes_per_node = cpus_per_node,
                      preschedule_cores = TRUE, job_array_task_limit = NULL, global_objects = NULL, 
                      pkgs = rev(.packages()), libPaths = NULL, 
                      rscript_path = NULL, r_template = NULL, sh_template = NULL, 
                      slurm_options = list(), submit = TRUE) {
    # Check inputs
    if (!is.list(x)) {
        stop("first argument to slurm_map should be a list")
    }
    if (!is.function(f)) {
        stop("second argument to slurm_map should be a function")
    }
    if (!is.numeric(nodes) || length(nodes) != 1) {
        stop("nodes should be a single number")
    }
    if (!is.numeric(cpus_per_node) || length(cpus_per_node) != 1) {
        stop("cpus_per_node should be a single number")
    }
    
    # Default templates
    if(is.null(r_template)) {
        r_template <- system.file("templates/slurm_map_R.txt", package = "rslurm")
    }
    if(is.null(sh_template)) {
        sh_template <- system.file("templates/submit_sh.txt", package = "rslurm")
    }

    jobname <- make_jobname(jobname)

    # Create temp folder
    tmpdir <- paste0("_rslurm_", jobname)
    dir.create(tmpdir, showWarnings = FALSE)
    
    # Unpack additional arguments
    more_args <- list(...)

    saveRDS(x, file = file.path(tmpdir, "x.RDS"))
    saveRDS(f, file = file.path(tmpdir, "f.RDS"))
    saveRDS(more_args, file = file.path(tmpdir, "more_args.RDS"))
    if (!is.null(global_objects)) {
        save(list = global_objects,
             file = file.path(tmpdir, "add_objects.RData"),
             envir = environment(f))
    }    
    
    # Get chunk size (nb. of list elements per node)
    # Special case if less list elements than CPUs in cluster
    if (length(x) < cpus_per_node * nodes) {
        nchunk <- cpus_per_node
    } else {
        nchunk <- ceiling(length(x) / nodes)
    }
    # Re-adjust number of nodes (only matters for small sets)
    nodes <- ceiling(length(x) / nchunk)

    # Create a R script to run function in parallel on each node
    template_r <- readLines(r_template)
    script_r <- whisker::whisker.render(template_r,
                    list(pkgs = pkgs,
                         add_obj = !is.null(global_objects),
                         nchunk = nchunk,
                         cpus_per_node = cpus_per_node,
                         processes_per_node = processes_per_node,
                         preschedule_cores = preschedule_cores,
                         libPaths = libPaths))
    writeLines(script_r, file.path(tmpdir, "slurm_run.R"))

    # Create submission bash script
    template_sh <- readLines(sh_template)
    slurm_options <- format_option_list(slurm_options)
    if (is.null(rscript_path)){
        rscript_path <- file.path(R.home("bin"), "Rscript")
    }
    script_sh <- whisker::whisker.render(template_sh,
                    list(max_node = nodes - 1,
                         job_array_task_limit = ifelse(is.null(job_array_task_limit), "", paste0("%", job_array_task_limit)),
                         cpus_per_node = cpus_per_node,
                         jobname = jobname,
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
    slurm_job(jobname, jobid, nodes)
}
