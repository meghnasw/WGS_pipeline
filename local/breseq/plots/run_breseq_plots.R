#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)

if (length(args) < 2) {
  stop(
    "Usage:\n  Rscript local/breseq/plots/run_breseq_plots.R <breseq_all_samples_long.tsv> <outdir>\n\n",
    "Example:\n  Rscript local/breseq/plots/run_breseq_plots.R /path/to/breseq_all_samples_long.tsv /path/to/breseq_plots\n"
  )
}

infile <- args[1]
outdir <- args[2]

if (!file.exists(infile)) stop("ERROR: Input file not found: ", infile)
dir.create(outdir, recursive = TRUE, showWarnings = FALSE)

# Ensure required packages exist
if (!requireNamespace("rmarkdown", quietly = TRUE)) {
  stop("ERROR: Package 'rmarkdown' is not installed. Install with:\n  install.packages('rmarkdown')\n")
}

# Find this script's location (works even if user runs from elsewhere)
script_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
if (length(script_arg) == 0) {
  stop("ERROR: Could not determine script path. Please run using: Rscript local/breseq/plots/run_breseq_plots.R ...")
}
script_path <- sub("^--file=", "", script_arg[1])
script_dir <- normalizePath(dirname(script_path), winslash = "/", mustWork = TRUE)

rmd_path <- file.path(script_dir, "breseq_plots.Rmd")
if (!file.exists(rmd_path)) stop("ERROR: Rmd not found: ", rmd_path)

# Render
rmarkdown::render(
  input = rmd_path,
  params = list(infile = infile, outdir = outdir),
  output_dir = outdir,
  quiet = FALSE
)

cat("Rendered report into: ", outdir, "\n", sep = "")
