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
