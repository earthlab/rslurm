#' Find the array index of jobs killed due to out-of-memory fault.
#'
#' @inheritParams get_slurm_out
#'
#' @return A vector of integers corresponding to the array index of jobs killed
#'   due to out-of-memory fault.
#'
#' @examples \dontrun{sjob_oomkilled <- get_oomKill_arrayindex(sjob = sjob)}
#'
#'@export
#'
get_oomKill_arrayindex <- function(slr_job, wait) {
    if (!(class(slr_job) == "slurm_job")) {
        stop("slr_job must be a slurm_job")
    }
    
    sjob_rst <- tryCatch(
        expr = {
            rslurm::get_slurm_out(slr_job = slr_job, wait = TRUE)
        },
        warning = function(w) {
            return("Processing incomplete.")
        },
        error = function(e){
            return("Error in slurm job(s).")
        }
    )
    
    if(sjob_rst != "Processing incomplete."){return(NULL)}
    
    # list result and output files
    sjob_out <-
        list.files(
            path = paste0("_rslurm_", slr_job$jobname),
            pattern = "^results|[.]out$",
            full.names = TRUE
        )
    # find jobs that ran to completion
    jobs_done <-
        sjob_out[grepl(pattern = "^results_", x = basename(sjob_out))]
    jobs_done <-
        regmatches(x = basename(jobs_done),
                   m = regexpr(pattern = "[[:digit:]]+", text = basename(jobs_done)))
    
    # find the index of jobs that did not produce results
    jobs_out <- sjob_out[grepl(pattern = "[.]out$", x = sjob_out)]
    jobs_out_index <-
        regmatches(x = basename(jobs_out),
                   m = regexpr(pattern = "[[:digit:]]+", text = basename(jobs_out)))
    
    jobs_notdone <- jobs_out[!jobs_out_index %in% jobs_done]
    
    # read the last line of output of unfinshed jobs
    jobs_notdone_output <-
        sapply(
            X = jobs_notdone,
            FUN = function(x) {
                xx <- readLines(x)
                xx[length(xx)]
            }
        )
    
    #find jobs that have oom-kill
    if(any(grepl(pattern = "oom-kill", x = jobs_notdone_output))){
        jobs_oomkill <-
            jobs_notdone[grep(pattern = "oom-kill", x = jobs_notdone_output)]
        jobs_rerun_arrayindex <-
            regmatches(x = basename(jobs_oomkill),
                       m = regexpr(pattern = "[[:digit:]]+", text = basename(jobs_oomkill)))
        jobs_rerun_arrayindex <- as.integer(jobs_rerun_arrayindex)
        jobs_rerun_arrayindex <- sort(x = jobs_rerun_arrayindex, decreasing = FALSE)
        return(jobs_rerun_arrayindex)
    } else {
        return(NULL)
    }
}

#' Read an sbatch script from an rslurm array job
#'
#' @inheritParams get_slurm_out
#' @param as_path Returns the path to the slurm array job script (T/F).
#'
#' @return The path to the slurm array job script (as_path = T) or a dataframe
#'   containing the slurm array job file inputs (as_path = F).
#'
#' @examples
#' \dontrun{get_sbatch_script(slr_job = sjob, as_path = T)}
#'
#' @export
#'
get_sbatch_script <- function(slr_job, as_path = TRUE) {
    if (!(class(slr_job) == "slurm_job")) {
        stop("slr_job must be a slurm_job")
    }
    script_dir <-
        list.dirs(".", recursive = FALSE, full.names = TRUE)[grepl(pattern = slr_job$jobname,
                                                                   x = list.dirs(".", recursive = FALSE))]
    script_dir <- normalizePath(path = script_dir, mustWork = TRUE)
    script <-
        list.files(path = script_dir,
                   pattern = "submit.sh",
                   full.names = TRUE)
    
    if (!file.exists(script)) {
        stop("no job script found.")
    }
    if(as_path){
        return(script)
    } else {
        script_x <-
            utils::read.delim(file = script,
                              header = FALSE,
                              stringsAsFactors = FALSE)
        attributes(script_x)$filename <- script
        return(script_x)
    }
}


#' Update a slurm array job script
#'
#' @inheritParams get_slurm_out
#' @param array_index A vector of integers indicating array indicies to be submitted with the sbatch job.
#' @param mem Amount of memeory to request for the sbatch array.
#' @param partition The partition to request for the sbatch.
#' @param write_script Write the script to file (T/F).
#' @param submit_job Should the array job be submitted (T/F). Only possible when
#'   \code{write_script = T}.
#'
#' @return Returns the updated script as a matrix or overwrites the existing
#'   slurm array job script.
#' @examples
#' \dontrun{update_sbatch_script(slr_job = sjob, mem = 1, write_script = FALSE) }
#'
#' @export
update_sbatch_script <-
    function(slr_job = NA,
             array_index = NULL,
             mem = NULL,
             partition = NULL,
             write_script = FALSE,
             submit_job = FALSE
    ) {
        if (!(class(slr_job) == "slurm_job")) {
            stop("slr_job must be a slurm_job")
        }
        script <- get_sbatch_script(slr_job = slr_job, as_path = FALSE)
        script_file <- attributes(script)$filename
        #update the array index
        if (!is.null(array_index)) {
            script[grep(pattern = "#SBATCH --array=", script[, 1]), 1] <-
                paste0("#SBATCH --array=", paste0(findIntRuns(array_index)))
        }
        #update the memory request
        if (!is.null(mem)) {
            if (any(grepl(pattern = "#SBATCH --mem=", script[, 1]))) {
                script[grep(pattern = "#SBATCH --mem=", script[, 1]), 1] <-
                    paste0("#SBATCH --mem=", paste0(mem, "G"))
            } else {
                script <- matrix(c(script[1:(nrow(script) - 1), ],
                                   paste0("#SBATCH --mem=", paste0(mem, "G")),
                                   script[nrow(script), ]))
            }
        }
        #update the partition request
        if (!is.null(partition)) {
            if (any(grepl(pattern = "#SBATCH --partition=", script[, 1]))) {
                script[grep(pattern = "#SBATCH --partition=", script[, 1]), 1] <-
                    paste0("#SBATCH --partition=", partition)
            } else {
                script <- matrix(c(
                    script[1:(nrow(script) - 1), ],
                    paste0("#SBATCH --partition=", partition),
                    script[nrow(script), ]
                ))
            }
        }
        script <- as.matrix(x = script)
        if(write_script) {
            utils::write.table(
                x = script,
                file = script_file,
                append = FALSE,
                quote = FALSE,
                row.names = FALSE,
                col.names = FALSE
            )
            if(submit_job){
                old_wd <- getwd()
                setwd(dirname(script_file))
                tryCatch({
                    system2(command = "sbatch", args = script_file)
                }, finally = setwd(old_wd))
            }
        } else {
            return(script)
        }
    }


#' Collapse runs of consecutive numbers Borrowed from
#'
#' @param run A sequence of integers.
#'
#' @return A sequence of integers with collapsed consecutive runs.
#'
#' @export
#'
findIntRuns <- function(run){
    rundiff <- c(1, diff(run))
    difflist <- split(run, cumsum(rundiff!=1))
    unlist(lapply(difflist, function(x){
        if(length(x) %in% 1:2) as.character(x) else paste0(x[1], "-", x[length(x)])
    }), use.names=FALSE)
}

