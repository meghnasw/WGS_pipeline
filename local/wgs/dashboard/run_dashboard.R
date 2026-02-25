#!/usr/bin/env Rscript
args <- commandArgs(trailingOnly = TRUE)
results_root <- if (length(args) >= 1) args[1] else "."

Sys.setenv(RESULTS_ROOT = results_root)

# Run the app from its folder
shiny::runApp("local/wgs/dashboard", launch.browser = TRUE)
