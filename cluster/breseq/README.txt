BRESEQ (cluster)

This module runs breseq for each sample using samples.tsv.

Prereqs:
1) Cluster setup + pipeline env exists (env/wgs includes breseq):
   PIPELINE_ROOT="$HOME/wgs_pipeline" SCRATCH_ROOT="/scratch/$USER/wgs_pipeline" bash cluster/bin/setup_cluster.sh

2) Data uploaded to /scratch/$USER/wgs_pipeline/data/

3) Create samples.tsv:
   cd ~/wgs_pipeline
   bash cluster/bin/make_samplesheet.sh data samples.tsv

Run breseq (one command):
   cd ~/wgs_pipeline
   bash cluster/breseq/bin/submit_breseq.sh --ref-gbk /path/to/reference.gbk

Optional resources:
   bash cluster/breseq/bin/submit_breseq.sh --ref-gbk /path/to/reference.gbk --cpus 8 --mem 24G --time 12:00:00

Outputs:
- results/breseq/<sample>/
- logs: results/breseq/logs/breseq-<job>_<task>.out/.err

Compare + annotate (optional; after breseq finishes):
   cd ~/wgs_pipeline
   REF_GBK=/path/to/reference.gbk OUT_ROOT=results/breseq bash cluster/breseq/bin/breseq_compare.sh

This creates:
- results/breseq/breseq_compare.tsv
- results/breseq/annotated_tsv/<sample>.tsv
- results/breseq/breseq_all_samples_long.tsv
