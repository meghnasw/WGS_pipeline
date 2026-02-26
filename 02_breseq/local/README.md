BRESEQ (local)

Goal:
- Generate plots + an HTML report from breseq_all_samples_long.tsv

Input needed:
- breseq_all_samples_long.tsv
  (produced by: cluster/breseq/bin/breseq_compare.sh)

Run (Mac/Linux):
    Rscript local/breseq/plots/run_breseq_plots.R "/path/to/breseq_all_samples_long.tsv" "/path/to/output_folder"

Run (Windows PowerShell):
    Rscript local\breseq\plots\run_breseq_plots.R "C:\path\to\breseq_all_samples_long.tsv" "C:\path\to\output_folder"

Outputs (in output_folder):
- HTML report
- PNG plots:
  - 01_mutations_per_sample.png
  - 02_mutation_types.png (if column 'type' exists)
  - 03_top_gene_total_mutations.png (if column 'gene_name' exists)
