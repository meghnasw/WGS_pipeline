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
0) One-time: get the repo locally (clone anywhere)
------------------------------------------------------------

Option A (recommended): clone the repo into a folder of your choice:

    cd <WHERE_YOU_WANT_THE_REPO>
    git clone https://github.com/meghnasw/WGS_pipeline.git wgs_pipeline
    cd wgs_pipeline

Option B: if you already cloned it earlier, update it:

    cd <PATH_TO_YOUR_EXISTING_wgs_pipeline_REPO>
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

If you get dependency errors, install missing packages as prompted.

Open R or RStudio and run:

```bash
install.packages(c(
  "shiny",
  "tidyverse",
  "DT",
  "ggplot2",
  "readr",
  "dplyr",
  "stringr"
))

```


------------------------------------------------------------
3) Run summary metrics script
------------------------------------------------------------

From your terminal (inside the repo root):

```bash
cd wgs_pipeline
```

Run:

```bash
Rscript 01_wgs/local/metrics/summarize_metrics.R </PATH/TO/RESULTS>
```

This script:

- Parses QUAST outputs
- Parses BUSCO outputs (if present)
- Combines metrics across samples

Check:

```bash
ls <PATH_TO_RESULTS>/combined_metrics.csv
```

------------------------------------------------------------
4) Launch the Shiny dashboard
------------------------------------------------------------

Run: 

```bash
Rscript 01_wgs/local/dashboard/app.R </PATH/TO/RESULTS>
```

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
