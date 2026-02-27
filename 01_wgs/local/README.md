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
2) Run summary metrics script
------------------------------------------------------------

From your terminal (inside the repo root):

```bash
cd wgs_pipeline
```

Run:

```bash
Rscript 01_wgs/local/metrics/summarize_metrics.R <PATH_TO_RESULTS>
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
3) Launch the Shiny dashboard (YOU MUST PASS RESULTS PATH)
------------------------------------------------------------

From repo root:

    cd <PATH_TO_YOUR_wgs_pipeline_REPO>

Run:

    Rscript 01_wgs/local/dashboard/app.R <PATH_TO_RESULTS>/results

Example:

    Rscript 01_wgs/local/dashboard/app.R ~/wgs_results/results

If you forget the argument, you can also do:

    RESULTS_ROOT=<LOCAL_RESULTS_ROOT>/results Rscript 01_wgs/local/dashboard/app.R

If the app does not render on the browser immediately, use the url displayed on the command line window.

------------------------------------------------------------
5) Troubleshooting
------------------------------------------------------------

Error:
  combined_metrics.csv not found

Fix:
- Run summarize_metrics.R first (step 2)
- Make sure you passed the correct results folder

Check:

    ls /<PATH_TO_RESULTS>/results/combined_metrics.csv


If packages fail to install:
- Make sure you have free disk space
- Make sure you have internet access
