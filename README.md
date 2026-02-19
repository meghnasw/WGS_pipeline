# WGS Group Pipeline (Cluster + Local Metrics)

This repository provides a beginner-friendly setup to run:
- WGS assembly + QC + annotation on the cluster (Slurm): FastQC/MultiQC → Shovill → QUAST → Prokka
- breseq on the cluster (Slurm)
- MLST on the cluster (Slurm)
- Summary metrics locally (R / optional Quarto)

The goal is: clone → one-time setup → submit jobs, with consistent outputs and logs.

---

## Repository layout

wgs-group-pipeline/
  scripts/
    WGS_pipelinev2.sh

  cluster/
    README.md
    bin/
      setup_cluster.sh
      validate_inputs.sh
      submit_wgs.sh
      submit_breseq.sh
      submit_mlst.sh
    slurm/
      run_wgs.slurm
      run_breseq_array.slurm
      run_mlst.slurm
    env/
      wgs.yaml
      breseq.yaml
      mlst.yaml
    docs/
      01_upload_data.md
      02_where_results_are.md
      03_common_errors.md

  local/
    README.md
    metrics/
      summarize_metrics.R
    reports/
      WGS_metrics.qmd

  examples/
    samplesheet_example.tsv
    naming_examples.md

Note: Some files may appear as the pipeline is built step-by-step.

---

## Quickstart (cluster / Slurm)

0) Clone the repo (cluster login node)

    cd ~
    git clone <REPO_URL> wgs_pipeline
    cd wgs_pipeline

1) One-time setup (creates env + scratch dirs + symlinks)

    bash cluster/bin/setup_cluster.sh

This sets up:
- ~/wgs_pipeline/env/wgs (conda environment)
- /scratch/$USER/wgs_pipeline/{data,results}
- ~/wgs_pipeline/data -> /scratch/$USER/wgs_pipeline/data
- ~/wgs_pipeline/results -> /scratch/$USER/wgs_pipeline/results

2) Upload reads to scratch

Place paired trimmed reads in:
- /scratch/$USER/wgs_pipeline/data/

Required naming:
- *_1_trimmed.fastq.gz
- *_2_trimmed.fastq.gz

3) Submit the WGS pipeline

    cd ~/wgs_pipeline
    sbatch cluster/slurm/run_wgs.slurm

4) Monitor job + view logs

    squeue -u $USER
    ls -lah ~/wgs_pipeline/results

Slurm logs:
- results/slurm-<jobid>.out
- results/slurm-<jobid>.err

---

## breseq (cluster)

breseq requires:
- paired reads per sample
- a reference genome (FASTA; optionally GenBank)

Typical run (once module is present):

    bash cluster/bin/submit_breseq.sh /path/to/reference.fasta

Outputs will be written under a results folder (documented in cluster/README.md).

---

## MLST (cluster)

MLST typically runs on assemblies (FASTA), e.g.:
- results/assemblies_for_qc/*.fasta

Typical run (once module is present):

    bash cluster/bin/submit_mlst.sh results/assemblies_for_qc

---

## Local metrics (run on laptop/desktop)

1) Copy or mount the cluster results/ folder locally.
2) Run the summary script:

    Rscript local/metrics/summarize_metrics.R /path/to/results

This writes:
- combined_metrics.csv

---

## Updating the pipeline

On the cluster, to update scripts/docs after changes are pushed:

    cd ~/wgs_pipeline
    git pull