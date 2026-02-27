# WGS_pipeline

This repository contains a Whole-Genome Sequencing (WGS) pipeline with two modules:

1. **01_wgs/** — from raw WGS reads to assembled genomes + QC summaries (cluster run + local R dashboard)
2. **02_breseq/** *(optional)* — breseq-based variant calling vs a reference (cluster run + local plots)

Both modules are designed for:
- **Science Cluster (UZH)** for compute (Slurm + conda)
- **Local machine** for visualization in **R**

---

## Repository structure

### 01_wgs/
- **cluster/**  
  Run the WGS pipeline on the cluster (Slurm + conda environment)

- **local/**  
  Summarize metrics and view the dashboard locally (R)

Start here: **01_wgs/README.md**

---

### 02_breseq/ (optional)
- **cluster/**  
  Run breseq on the cluster (variant calling vs reference)

- **local/**  
  Plot breseq results locally (R)

---

## Getting started

- WGS module: `01_wgs/README.md`
- Cluster WGS instructions: `01_wgs/cluster/README.md`
- Local WGS dashboard: `01_wgs/local/README.md`