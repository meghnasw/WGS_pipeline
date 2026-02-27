## Repository Structure

This repository contains a Whole-Genome Sequencing (WGS) pipeline wiht two modules. The first module contains a bioinformatics pipeline from processing raw WGS data to assembled genomes and ends with a Shiny App to visualize all the quality control checks. The second module is an optional module that contains Breseq which is useful in analyzing experimental evolution data. In both modules the analyses is set up on the Science Cluster at UZH and the vizualisations are generated in R locally.

---

### 01_wgs/

**cluster/**  
Run the WGS pipeline on the cluster (Slurm + conda environment).

**local/**  
Summarize metrics and view the dashboard locally (R).

---

### 02_breseq/ (optional)

**cluster/**  
Run breseq on the cluster (variant calling vs reference).

**local/**  
Plot breseq results locally (R).

---

## Getting Started

Start here: 01_wgs/
