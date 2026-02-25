# WGS Pipeline (cluster run + local R metrics)

This repository is designed for beginners:
1) Run the WGS pipeline on the cluster (Slurm)
2) Copy results back and summarize/visualize locally in R

Start here:
- Cluster setup + run instructions: cluster/README.md
- Local metrics (R): local/README.md

---

## Repository structure

wgs-group-pipeline/
  README.md

  scripts/
    WGS_pipelinev2.sh                 # main pipeline script (cluster job runs this)

  cluster/
    README.md                         # beginner cluster instructions (setup -> upload -> samplesheet -> submit -> logs)
    bin/
      setup_cluster.sh                # one-time: conda env + scratch dirs + symlinks
      make_samplesheet.sh             # one-time per dataset: generates samples.tsv from data/ (filters out _U1/_U2/untrimmed)
      submit_wgs.sh                   # submits the job with resources + BUSCO lineage in one command
    slurm/
      run_wgs.slurm                   # Slurm runner (portable; uses SLURM_SUBMIT_DIR)
    docs/
      01_upload_data.md               # rsync/scp recipes + naming rules
      02_where_results_are.md         # where outputs/logs go
      03_common_errors.md             # common failures + fixes

  local/
    README.md                         # how to run R scripts locally on results folder
    metrics/
      summarize_metrics.R             # creates combined_metrics.csv
    reports/
      WGS_metrics.qmd                 # optional Quarto report (local)

  examples/
    samplesheet_example.tsv
    naming_examples.md

---

## Workflow overview

### A) Cluster
- Clone the repo on the cluster
- Run one-time setup (creates conda env + scratch dirs)
- Upload FASTQ files to scratch
- Generate samples.tsv (auto-detect correct read pairs)
- Submit the pipeline (resources + BUSCO lineage set in one command)

All details: cluster/README.md

### B) Local (R)
- Copy results back from the cluster (or mount shared storage)
- Run the R metrics script to generate a CSV summary
- Optional: render a Quarto report

All details: local/README.md
