# 01_wgs: Local workflow (metrics + dashboard)

This module is run on your local machine (Mac/Windows/Linux) using R.

Inputs:
- QUAST report folder: quast_multi/
- MultiQC report: fastqc_multiqc/multiqc/multiqc_report.html
- Prokka outputs per sample: <sample>/prokka_out/
- BUSCO outputs per sample (optional): <sample>/busco_out/

--------------------------------------------------------------------
1) Copy results from the cluster to local storage
--------------------------------------------------------------------

Recommended: copy the whole results folder to a local directory.

Example (run on your laptop; adjust paths):

rsync -avz --progress \
  <user>@cluster.s3it.uzh.ch:/scratch/<user>/wgs_pipeline/results/ \
  /PATH/TO/LOCAL/All_results/

Now your local results_root is:
  /PATH/TO/LOCAL/All_results

--------------------------------------------------------------------
2) Create combined_metrics.csv
--------------------------------------------------------------------

From the repo root on your laptop:

Rscript 01_wgs/local/metrics/summarize_metrics.R "/PATH/TO/LOCAL/All_results" "/PATH/TO/LOCAL/All_results/combined_metrics.csv"

This produces:
- combined_metrics.csv

--------------------------------------------------------------------
3) Run the dashboard
--------------------------------------------------------------------

The dashboard expects:
- combined_metrics.csv in the dashboard folder OR in results_root (recommended: copy it into results_root)
- multiqc_report.html available (usually at results_root/fastqc_multiqc/multiqc/multiqc_report.html)

Recommended layout:
  /PATH/TO/LOCAL/All_results/
    combined_metrics.csv
    fastqc_multiqc/multiqc/multiqc_report.html
    quast_multi/
    <sample folders...>

Run:

cd 01_wgs/local/dashboard
Rscript run_dashboard.R "/PATH/TO/LOCAL/All_results"

