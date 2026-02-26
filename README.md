# WGS Pipeline (cluster run + local R metrics)

WGS_pipeline (module-based)

This repo has two modules:

01_wgs/
  - cluster/: run the WGS pipeline on the cluster (Slurm + conda env)
  - local/:   summarize metrics + view dashboard locally (R)

02_breseq/ (optional)
  - cluster/: run breseq on the cluster (variant calling vs reference)
  - local/:   plot breseq results locally (R)

Start here:
  01_wgs/cluster/README.md
Then:
  01_wgs/local/README.md
Optional:
  02_breseq/cluster/README.md
  02_breseq/local/README.md