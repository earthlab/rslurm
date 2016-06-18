# Utility functions for rslurm package (not exported)

# Convert a function to string
func_to_str <- function(f) {
    fstr <- paste(capture.output(f), collapse = "\n")
    gsub("<environment: [A-Za-z0-9]+>", "", fstr)
}


# Make jobname by cleaning user-provided name or (if NA) generate one from clock
make_jobname <- function(name) {
    if (is.na(name)) {
        paste0("slr", as.integer(Sys.time()) %% 10000)
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
}
