# 02_breseq: Cluster workflow (optional module)

This module runs breseq on the cluster (variant calling vs a reference).

Prereqs:
- Conda env already created via: 01_wgs/cluster/bin/setup_cluster.sh
- breseq inputs uploaded to scratch (see below)

--------------------------------------------------------------------
1) Prepare inputs on scratch
--------------------------------------------------------------------

Recommended scratch layout:

/scratch/$USER/wgs_pipeline/data/breseq/
  breseq_samples.txt
  ref/<reference>.gbk
  reads/<sample>_1.fastq.gz
  reads/<sample>_2.fastq.gz

breseq_samples.txt should contain one prefix per line, WITHOUT _1/_2.
Example line:
/scratch/$USER/wgs_pipeline/data/breseq/reads/sampleA

That means files exist:
.../sampleA_1.fastq.gz
.../sampleA_2.fastq.gz

--------------------------------------------------------------------
2) Run breseq as a Slurm array
--------------------------------------------------------------------

From ~/wgs_pipeline (cluster):

sbatch --array=1-<N> 02_breseq/cluster/slurm/run_breseq_array.slurm

Where <N> = number of lines in breseq_samples.txt:

wc -l /scratch/$USER/wgs_pipeline/data/breseq/breseq_samples.txt

Outputs will go to:
  /scratch/$USER/wgs_pipeline/results/breseq/<sample>/

Logs:
  results/breseq-<jobid>_<taskid>.out
  results/breseq-<jobid>_<taskid>.err

--------------------------------------------------------------------
3) Compare / annotate outputs (gdtools)
--------------------------------------------------------------------

Run (from ~/wgs_pipeline):

bash 02_breseq/cluster/bin/breseq_compare.sh

This produces:
- results/breseq/breseq_compare.tsv
- results/breseq/breseq_all_samples_long.tsv

--------------------------------------------------------------------
4) Copy the combined TSV to your laptop
--------------------------------------------------------------------

rsync -avz --progress \
  <user>@cluster.s3it.uzh.ch:/scratch/<user>/wgs_pipeline/results/breseq/breseq_all_samples_long.tsv \
  /PATH/TO/LOCAL/breseq/

Then follow:
02_breseq/local/README.md
