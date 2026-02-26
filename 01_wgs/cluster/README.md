# 01_wgs: Cluster workflow (beginner)

This module runs the WGS pipeline on the cluster using Slurm + a conda env (miniforge module).

Pipeline order:
FastQC/MultiQC -> Shovill -> QUAST -> Prokka -> BUSCO (optional)

--------------------------------------------------------------------
0) One-time: clone the repo (on cluster login node)
--------------------------------------------------------------------

cd ~
git clone https://github.com/meghnasw/WGS_pipeline.git
cd WGS_pipeline

--------------------------------------------------------------------
1) One-time: cluster setup (env + scratch folders + symlinks)
--------------------------------------------------------------------

This creates:
- env:     ~/wgs_pipeline/env/wgs
- data:    ~/wgs_pipeline/data    -> /scratch/$USER/wgs_pipeline/data
- results: ~/wgs_pipeline/results -> /scratch/$USER/wgs_pipeline/results

Run (from the repo root):

PIPELINE_ROOT="$HOME/wgs_pipeline" \
SCRATCH_ROOT="/scratch/$USER/wgs_pipeline" \
bash 01_wgs/cluster/bin/setup_cluster.sh

Check that symlinks exist:

cd ~/wgs_pipeline
ls -lah data results

--------------------------------------------------------------------
2) Upload FASTQ data to scratch
--------------------------------------------------------------------

Put your paired FASTQs into:

/scratch/$USER/wgs_pipeline/data/

Allowed file formats:
- .fastq
- .fastq.gz

Supported naming (R1/R2):
- *_1.fastq(.gz) / *_2.fastq(.gz)
- *_1_trimmed.fastq(.gz) / *_2_trimmed.fastq(.gz)
- *_R1.fastq(.gz) / *_R2.fastq(.gz)
- *_R1_001.fastq(.gz) / *_R2_001.fastq(.gz)

Excluded (never processed):
- anything containing _U1 or _U2
- anything containing "untrimmed"

Example (run on your laptop; adjust paths):

rsync -avP \
  --include="*.fastq" \
  --include="*.fastq.gz" \
  --exclude="*" \
  /PATH/TO/READS/ \
  <user>@cluster.s3it.uzh.ch:/scratch/<user>/wgs_pipeline/data/

Verify on cluster:

ls -lh /scratch/$USER/wgs_pipeline/data | head
ls /scratch/$USER/wgs_pipeline/data | grep '_U' || echo "No U files found"

--------------------------------------------------------------------
3) Create samples.tsv (auto-detect pairs)
--------------------------------------------------------------------

From repo root on cluster:

cd ~/wgs_pipeline
bash 01_wgs/cluster/bin/make_samplesheet.sh data samples.tsv

Inspect:

head -n 5 samples.tsv
wc -l samples.tsv

(samples.tsv includes a header line; number of samples = lines - 1)

--------------------------------------------------------------------
4) Submit the pipeline (resources from ONE command)
--------------------------------------------------------------------

You do NOT edit the Slurm script.
You pass resources in the submit command.

Example WITHOUT BUSCO:

cd ~/wgs_pipeline
bash 01_wgs/cluster/bin/submit_wgs.sh \
  --partition standard \
  --time 10:00:00 \
  --cpus 8 \
  --mem 24G

Example WITH BUSCO (recommended):

bash 01_wgs/cluster/bin/submit_wgs.sh \
  --partition standard \
  --time 10:00:00 \
  --cpus 8 \
  --mem 24G \
  --busco-lineage bacteria_odb10 \
  --busco-downloads /scratch/$USER/busco_downloads

--------------------------------------------------------------------
5) Monitor the job + logs
--------------------------------------------------------------------

squeue -u $USER

Logs go to:
- results/slurm-<jobid>.out
- results/slurm-<jobid>.err

Follow logs:

tail -f results/slurm-<jobid>.out
tail -f results/slurm-<jobid>.err

Check resources after completion:

sacct -j <jobid> --format=JobID,State,Elapsed,MaxRSS,ReqMem,AllocCPUS

--------------------------------------------------------------------
6) Outputs
--------------------------------------------------------------------

Key outputs (through the results symlink):
- results/fastqc_multiqc/multiqc/          (MultiQC report)
- results/assemblies_for_qc/<sample>.fasta (assemblies)
- results/quast_multi/                     (QUAST report)
- results/<sample>/prokka_out/             (Prokka outputs)
- results/<sample>/busco_out/              (BUSCO outputs if enabled)
- benchmarking_all_steps.log               (combined benchmarking summary)

--------------------------------------------------------------------
7) Next step: view results locally
--------------------------------------------------------------------

Copy results off the cluster and then follow:
01_wgs/local/README.md
