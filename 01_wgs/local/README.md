# WGS local metrics + Shiny dashboard (beginner workflow)

This part of the pipeline runs locally (your laptop or desktop).

Goal:
- Re-clone the repo locally
- Copy results from the cluster
- Summarize WGS results into tables
- Launch the Shiny dashboard

This does NOT require Slurm.
It uses the results folder produced by the cluster pipeline.


------------------------------------------------------------
0) One-time: clone the repo locally (your laptop)
------------------------------------------------------------

Open a terminal on your laptop and run:

    cd ~
    git clone https://github.com/meghnasw/WGS_pipeline.git wgs_pipeline
    cd wgs_pipeline

If you already cloned it earlier, update it:

    cd ~/wgs_pipeline
    git pull


------------------------------------------------------------
1) Folder structure (local machine)
------------------------------------------------------------

Your local folder should look like:

```text
wgs_pipeline/
  ├── 01_wgs/
  │     └── local/
  ├── results/
  │     ├── fastqc_multiqc/
  │     ├── assemblies_for_qc/
  │     ├── quast_multi/
  │     ├── busco/
  │     └── <sample folders>
  └── ...
```

If you copied only selected folders, make sure you at least have:

- results/assemblies_for_qc/
- results/quast_multi/
- results/fastqc_multiqc/
- results/busco/   (if BUSCO was enabled)


------------------------------------------------------------
2) Install R packages (one-time setup)
------------------------------------------------------------

Open R or RStudio and run:

install.packages(c(
  "shiny",
  "tidyverse",
  "DT",
  "ggplot2",
  "readr",
  "dplyr",
  "stringr"
))

If you get dependency errors, install missing packages as prompted.


------------------------------------------------------------
3) Run summary metrics script
------------------------------------------------------------

From your terminal (inside the repo root):

cd wgs_pipeline

Run:

Rscript 01_wgs/local/summary_metrics.R

This script:

- Parses QUAST outputs
- Parses BUSCO outputs (if present)
- Combines metrics across samples
- Writes summary tables to:

results/summary_metrics/


Check:

ls results/summary_metrics/


------------------------------------------------------------
4) Launch the Shiny dashboard
------------------------------------------------------------

From repo root:

Rscript 01_wgs/local/app.R

OR open R and run:

shiny::runApp("01_wgs/local")

Your browser should open automatically.

If not, copy the URL printed in the console and paste it into your browser.


------------------------------------------------------------
5) What the dashboard shows
------------------------------------------------------------

The Shiny app allows you to:

- View assembly statistics
- Compare N50, contig count, genome size
- Inspect BUSCO completeness (if available)
- Download summary tables


------------------------------------------------------------
6) Troubleshooting
------------------------------------------------------------

If the app says files are missing:

- Check that the results/ folder is present
- Make sure you ran the cluster pipeline successfully
- Confirm that summary_metrics.R ran without errors

If R cannot find a package:

install.packages("missing_package_name")


------------------------------------------------------------
7) Recommended workflow
------------------------------------------------------------

Cluster:
  Run full WGS pipeline

Local:
  Copy results/
  Run summary_metrics.R
  Launch Shiny app


------------------------------------------------------------
8) Re-running after new samples
------------------------------------------------------------

If you add new samples and rerun the cluster pipeline:

1) Copy updated results/ folder
2) Run summary_metrics.R again
3) Restart the Shiny app


------------------------------------------------------------
9) No scratch cleanup needed
------------------------------------------------------------

Local analysis does not use scratch.

All processing is done inside:

results/