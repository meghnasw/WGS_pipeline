# 02_breseq: Local workflow (plots)

Input:
- breseq_all_samples_long.tsv

Run:

Rscript 02_breseq/local/plots/run_breseq_plots.R \
  "/PATH/TO/breseq_all_samples_long.tsv" \
  "/PATH/TO/output_plots_folder"

Outputs:
- PNG plots written to the output folder
