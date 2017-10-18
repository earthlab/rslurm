# Utility functions for rslurm package (not exported)


# Make jobname by cleaning user-provided name or (if NA) generate one
# from base::tempfile
make_jobname <- function(name) {
    if (is.na(name)) {
        tmpfile <- tempfile("_rslurm_", tmpdir=".")
        strsplit(tmpfile, '_rslurm_', TRUE)[[1]][[2]]
    } else {
        jobname <- gsub("[[:space:]]+", "_", name)
        gsub("[^0-9A-Za-z_]", "", jobname)
    }
}


# Format sbatch options into nested list for templates
format_option_list <- function(slurm_options) {
    if (length(slurm_options) == 0) {
        slurm_flags <- slurm_options
    } else {
        is_flag <- sapply(slurm_options, isTRUE)
        slurm_flags <- lapply(names(slurm_options[is_flag]), function(x) {
            list(name = x)
        })
        slurm_options <- slurm_options[!is_flag]
        slurm_options <- lapply(seq_along(slurm_options), function(i) {
            list(name = names(slurm_options)[i], value = slurm_options[[i]])
        })        
    }
    list(flags = slurm_flags, options = slurm_options)
}


# Run an array job (output of slurm_apply) locally; used in package tests
local_slurm_array <- function(slr_job) {
    olddir <- getwd()
    rscript_path <- file.path(R.home("bin"), "Rscript")
    setwd(paste0("_rslurm_", slr_job$jobname))
    tryCatch({
        writeLines(c(paste0("for (i in 1:", slr_job$nodes, " - 1) {"),
                     "Sys.setenv(SLURM_ARRAY_TASK_ID = i)",
                     "source('slurm_run.R')", "}"), "local_run.R")
        system(paste(rscript_path, "--vanilla local_run.R"))
    }, finally = setwd(olddir))
    return(slr_job)
}

# Submit job
submit_slurm_job <- function(tmpdir) {
    old_wd <- setwd(tmpdir)
    tryCatch({
        system("sbatch submit.sh")
    }, finally = setwd(old_wd))
}

# Submit dummy job with a dependency via srun to block R process
wait_for_job <- function(slr_job) {
    queued <- system(
        paste('test -z "$(squeue -hn', slr_job$jobname, '2>/dev/null)"'),
        ignore.stderr = TRUE)
    if (queued) {
        srun <- sprintf(paste('srun',
            '--nodes=1',
            '--time=0:1',
            '--output=/dev/null',
            '--quiet',
            '--dependency=singleton',
            '--job-name=%s',
            'echo 0'),
            slr_job$jobname)
        system(srun)
    }
    return()
}
