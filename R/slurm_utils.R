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

# Submit job
submit_slurm_job <- function(tmpdir) {
    old_wd <- setwd(tmpdir)
    sys_out <- tryCatch({
            system("sbatch submit.sh", intern = TRUE)
        }, finally = setwd(old_wd))
    message(sys_out)
    sys_out <- strsplit(sys_out, " ")[[1]]
    jobid <- sys_out[length(sys_out)]
    return(jobid)
}

# Submit dummy job with a dependency via sbatch to block R process
wait_for_job <- function(slr_job) {
    queued <- system(
        paste('test -z "$(squeue -hn', slr_job$jobname, '2>/dev/null)"'),
        ignore.stderr = TRUE)
    if (queued) {
        block_cmd <- sprintf('sbatch --nodes=1 --output=/dev/null --time=00:01:00 --dependency=singleton --job-name=%s --wait --wrap="hostname"', slr_job$jobname)
        system(block_cmd, intern=TRUE)
    }
    return()
}
