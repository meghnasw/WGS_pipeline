# Local metrics (R)

Goal: create a single CSV summary file from a pipeline results folder:
- contigs + N50 (QUAST)
- gene count (Prokka)
- BUSCO completeness (if present)

Output:
- combined_metrics.csv

------------------------------------------------------------
0) Prerequisites
------------------------------------------------------------

You need:
- R installed
- the tidyverse package

In R:

    install.packages("tidyverse")

------------------------------------------------------------
1) Get the results folder onto your computer
------------------------------------------------------------

You need the results folder from the cluster (or a shared storage folder that contains the same structure).

Option A (recommended): copy results from cluster using rsync (Mac/Linux)
Run this on your laptop/desktop (NOT on the cluster):

```bash
    rsync -avz --progress \
      <user>@cluster.s3it.uzh.ch:/scratch/<user>/wgs_pipeline/results/ \
      /path/to/local/results/
```bash

Example destination on Mac:
- /Volumes/.../MyProject/results/

Option B: copy results using Windows PowerShell (scp)
Windows PowerShell (requires OpenSSH enabled on Windows 10/11):

```bash
    scp -r <user>@cluster.s3it.uzh.ch:/scratch/<user>/wgs_pipeline/results/ C:\Users\<you>\Documents\results\
```

If you have WinSCP, you can also download via GUI:
- Remote: /scratch/<user>/wgs_pipeline/results/
- Local: wherever you want

------------------------------------------------------------
2) Run the summary script
------------------------------------------------------------

Script location in this repo:
- local/metrics/summarize_metrics.R

Mac / Linux:
```bash
    Rscript local/metrics/summarize_metrics.R "/path/to/results"
```
Example:

    Rscript local/metrics/summarize_metrics.R "/Volumes/.../All_results"

Windows (PowerShell):

    Rscript local\metrics\summarize_metrics.R "C:\Users\<you>\Documents\All_results"

------------------------------------------------------------
3) Output
------------------------------------------------------------

By default the script writes:
- <results_root>/combined_metrics.csv

Examples:
- /Volumes/sgr_rk/.../All_results/combined_metrics.csv
- C:\Users\<you>\Documents\All_results\combined_metrics.csv

If you want to choose a custom output location:

Mac / Linux:

```bash
    Rscript local/metrics/summarize_metrics.R "/path/to/results" "/path/to/output/combined_metrics.csv"
```

Windows:

```bash
    Rscript local\metrics\summarize_metrics.R "C:\path\to\results" "C:\path\to\combined_metrics.csv"
```

------------------------------------------------------------
Notes / common issues
------------------------------------------------------------

- If you get: ERROR: QUAST report not found
  Make sure your results folder contains:
  - quast_multi/report.tsv
  (or quast_multi/combined_report.tsv)

- BUSCO is optional.
  If BUSCO short_summary files are not found, BUSCO columns will be empty/NA.

- The script automatically ignores non-sample folders like:
  fastqc_multiqc, assemblies_for_qc, quast_multi, busco_downloads, mlst.*, and slurm logs.