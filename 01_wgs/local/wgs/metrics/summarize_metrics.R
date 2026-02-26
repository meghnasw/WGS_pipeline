#!/usr/bin/env Rscript
######
# title:  "WGS Pipeline metrics"
# author: "Meghna Swayambhu"
# date:   "27/11/2025"
# edited: "20/02/2026"
#
# Usage:
#   Rscript local/metrics/summarize_metrics.R /path/to/All_results
#   Rscript local/metrics/summarize_metrics.R /path/to/All_results /path/to/output.csv
######

suppressPackageStartupMessages({
  library(tidyverse)
})

# -------------------------
# Args: results_root, output_csv (optional)
# -------------------------
args <- commandArgs(trailingOnly = TRUE)
results_root <- if (length(args) >= 1) args[1] else "results"
output_csv   <- if (length(args) >= 2) args[2] else file.path(results_root, "combined_metrics.csv")

if (!dir.exists(results_root)) {
  stop(
    "ERROR: results_root directory not found: ", results_root,
    "\nUsage: Rscript summarize_metrics.R /path/to/All_results [/path/to/output.csv]"
  )
}

message("Using results_root: ", normalizePath(results_root, winslash = "/", mustWork = FALSE))
message("Will write CSV to:  ", normalizePath(output_csv, winslash = "/", mustWork = FALSE))

# -------------------------
# Helper: make a unique ID for each sample folder (kept from your script)
# -------------------------
make_sample_id <- function(d) {
  s <- basename(d)
  src <- basename(dirname(d))
  gp <- basename(dirname(dirname(d)))
  tag <- ifelse(src == basename(results_root), gp, src)
  paste0(s, "__", tag)
}

# -------------------------
# List sample dirs (robust: only keep dirs that contain pipeline outputs)
# -------------------------
all_dirs <- list.dirs(results_root, full.names = TRUE, recursive = FALSE)

ignore <- c(
  "assemblies_for_qc", "fastqc_multiqc", "quast_multi",
  "busco", "busco_downloads",
  "mlst.out",
  "results", "logs"
)

all_dirs <- all_dirs[!basename(all_dirs) %in% ignore]

sample_dirs <- all_dirs[
  dir.exists(file.path(all_dirs, "prokka_out")) |
    dir.exists(file.path(all_dirs, "busco_out")) |
    dir.exists(file.path(all_dirs, "shovill_out"))
]

if (length(sample_dirs) == 0) {
  stop(
    "ERROR: No sample directories found under results_root: ", results_root,
    "\nExpected sample folders containing prokka_out/ or busco_out/ or shovill_out/."
  )
}

# sanity: detect duplicates in folder names
dup_names <- basename(sample_dirs)[duplicated(basename(sample_dirs))]
if (length(dup_names) > 0) {
  message("WARNING: duplicate sample folder names found (will disambiguate with __tag):")
  message(paste(unique(dup_names), collapse = ", "))
}

# =========================
# 1) QUAST (combined report)
# =========================
quast_candidates <- c(
  file.path(results_root, "quast_multi", "combined_report.tsv"),
  file.path(results_root, "quast_multi", "report.tsv")
)
quast_path <- quast_candidates[file.exists(quast_candidates)][1]
if (is.na(quast_path)) {
  stop(
    "ERROR: QUAST report not found. Looked for:\n- ",
    paste(quast_candidates, collapse = "\n- ")
  )
}

quast <- readr::read_tsv(quast_path, show_col_types = FALSE)

# Remove readr's ... suffixes AND drop duplicated sample columns
base <- sub("\\.\\.\\..*$", "", names(quast))
keep <- !duplicated(base)
quast <- quast[, keep]
names(quast) <- base[keep]

metric_col <- names(quast)[1]

quast_summary <- quast %>%
  rename(metric_raw = all_of(metric_col)) %>%
  filter(metric_raw %in% c("# contigs (>= 0 bp)", "N50")) %>%
  pivot_longer(cols = -metric_raw, names_to = "sample", values_to = "value") %>%
  mutate(
    metric = recode(
      metric_raw,
      "# contigs (>= 0 bp)" = "contigs",
      "N50" = "n50"
    ),
    value = suppressWarnings(as.numeric(value))
  ) %>%
  select(sample, metric, value) %>%
  pivot_wider(names_from = metric, values_from = value) %>%
  mutate(sample_clean = sub("\\.\\.\\..*$", "", sample))

# =========================
# 2) PROKKA (gene counts)
# =========================
prokka_summary <- purrr::map_dfr(sample_dirs, function(d) {
  s <- basename(d)
  prokka_dir <- file.path(d, "prokka_out")
  if (!dir.exists(prokka_dir)) return(NULL)
  
  preferred <- file.path(prokka_dir, paste0(s, ".tsv"))
  if (file.exists(preferred)) {
    tsv <- preferred
  } else {
    tsv_files <- list.files(prokka_dir, pattern = "\\.tsv$", full.names = TRUE)
    if (length(tsv_files) == 0) return(NULL)
    tsv <- tsv_files[1]
  }
  
  ann <- readr::read_tsv(tsv, show_col_types = FALSE)
  
  ftype_col <- intersect(c("ftype", "type"), names(ann))
  gene_count <- if (length(ftype_col) == 1) {
    sum(ann[[ftype_col]] == "CDS", na.rm = TRUE)
  } else {
    nrow(ann)
  }
  
  tibble::tibble(
    sample = s,
    sample_id = make_sample_id(d),
    sample_clean = as.character(s),
    gene_count = gene_count,
    prokka_file = basename(tsv)
  )
}) %>% distinct(sample_clean, .keep_all = TRUE)

# =========================
# 3) BUSCO (robust: supports multiple layouts)
# =========================
find_busco_summaries <- function(root) {
  unique(c(
    # Layout A: per-sample busco_out
    Sys.glob(file.path(root, "*", "busco_out", "*", "short_summary*.txt")),
    # Layout B: centralized busco folder (if used)
    Sys.glob(file.path(root, "busco", "*", "short_summary*.txt")),
    # Layout C: busco-only folder (e.g. microbesNG_busco_analyses)
    Sys.glob(file.path(root, "*_busco", "short_summary*.txt"))
  ))
}

parse_busco_summary <- function(path) {
  run_dir <- basename(dirname(path))
  if (!grepl("_busco$", run_dir)) {
    run_dir2 <- basename(dirname(dirname(path)))
    if (grepl("_busco$", run_dir2)) run_dir <- run_dir2
  }
  sample <- sub("_busco$", "", run_dir)
  
  lines <- readLines(path, warn = FALSE)
  line <- lines[grepl("C:", lines)][1]
  if (length(line) == 0 || is.na(line)) return(NULL)
  
  C <- sub(".*C:([0-9.]+)%.*", "\\1", line)
  F <- sub(".*F:([0-9.]+)%.*", "\\1", line)
  M <- sub(".*M:([0-9.]+)%.*", "\\1", line)
  
  tibble::tibble(
    sample = sample,
    sample_clean = as.character(sample),
    busco_complete = as.numeric(C),
    busco_fragmented = as.numeric(F),
    busco_missing = as.numeric(M),
    busco_file = basename(path)
  )
}

busco_files <- find_busco_summaries(results_root)

if (length(busco_files) == 0) {
  message("NOTE: No BUSCO short_summary files found under: ", results_root)
  busco_summary <- tibble()
} else {
  message("Found BUSCO summaries: ", length(busco_files))
  busco_summary <- purrr::map_dfr(busco_files, parse_busco_summary) %>%
    distinct(sample_clean, .keep_all = TRUE)
}

# =========================
# 4) Combine
# =========================
combined <- quast_summary %>%
  left_join(prokka_summary %>% select(sample_clean, gene_count), by = "sample_clean") %>%
  left_join(
    busco_summary %>% select(sample_clean, busco_complete, busco_fragmented, busco_missing),
    by = "sample_clean"
  ) %>%
  arrange(sample_clean)

# Diagnostics
missing_prokka <- anti_join(quast_summary %>% distinct(sample_clean), prokka_summary %>% distinct(sample_clean), by = "sample_clean")
missing_busco  <- anti_join(quast_summary %>% distinct(sample_clean), busco_summary  %>% distinct(sample_clean), by = "sample_clean")

if (nrow(missing_prokka) > 0) {
  message("NOTE: QUAST samples with no Prokka match (showing up to 50):")
  print(missing_prokka %>% head(50))
}
if (nrow(missing_busco) > 0) {
  message("NOTE: QUAST samples with no BUSCO match (showing up to 50):")
  print(missing_busco %>% head(50))
}

# Write CSV
dir.create(dirname(output_csv), showWarnings = FALSE, recursive = TRUE)
readr::write_csv(combined, output_csv)

print(combined, n = 200)