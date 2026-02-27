# breseq pipeline on the cluster (beginner workflow)

This pipeline runs on the S3IT cluster using Slurm + the existing conda env.

IMPORTANT:
All commands in this README are run ON THE CLUSTER
(except rsync upload commands, which are run from your laptop).

Goal:
- Log into the cluster
- Upload FASTQ files AND a reference .gbk file
- Create sample list
- Submit breseq as a Slurm array
- Compare mutations across samples

------------------------------------------------------------
0) Log into the cluster
------------------------------------------------------------

You must be on the University network
(direct WIFI or VPN).

From your laptop terminal:

    ssh -l <user> cluster.s3it.uzh.ch

After login, you are on the cluster login node.

Now move into your repo:

    cd ~/wgs_pipeline

If the repo is not there:

    cd ~
    git clone https://github.com/meghnasw/WGS_pipeline.git wgs_pipeline
    cd wgs_pipeline


------------------------------------------------------------
1) One-time: cluster setup (if not done already)
------------------------------------------------------------

If you already ran setup for 01_wgs, skip this.

Otherwise:

    PIPELINE_ROOT="$HOME/wgs_pipeline" SCRATCH_ROOT="/scratch/$USER/wgs_pipeline" bash 01_wgs/cluster/bin/setup_cluster.sh

This creates:
- ~/wgs_pipeline/env/wgs
- data -> /scratch/$USER/wgs_pipeline/data
- results -> /scratch/$USER/wgs_pipeline/results


------------------------------------------------------------
2) Upload FASTQ files AND reference file
------------------------------------------------------------

IMPORTANT:
You must upload:
- Paired FASTQ files
- Reference genome in GenBank format (.gbk)

All files must go to:

    /scratch/$USER/wgs_pipeline/data/breseq/

Recommended structure:

    data/breseq/
        ├── fastq/
        └── ref/
Create respective folders for breseq:

```bash
mkdir -p /scratch/mswaya/wgs_pipeline/data/breseq/fastq
mkdir -p /scratch/mswaya/wgs_pipeline/data/breseq/ref
```

From your laptop (NOT on cluster):

rsync -avP \
  --include='*_1_trimmed.fastq.gz' \
  --include='*_2_trimmed.fastq.gz' \
  --exclude='*' \
  <PATH_TO_READS>/ \
  <user>@cluster.s3it.uzh.ch:/scratch/<user>/wgs_pipeline/data/breseq/fastq/
	  
Upload reference:

rsync -avP \
<PATH_TO_REFERENCE>/reference.gbk \
<user>@cluster.s3it.uzh.ch:/scratch/<user>/wgs_pipeline/data/breseq/ref

Verify on cluster:

    ls -lh /scratch/$USER/wgs_pipeline/data/breseq/fastq
    ls -lh /scratch/$USER/wgs_pipeline/data/breseq/ref


------------------------------------------------------------
3) Create breseq sample list
------------------------------------------------------------

On cluster:

    cd ~/wgs_pipeline

Generate sample prefixes automatically:

    ls /scratch/$USER/wgs_pipeline/data/breseq/fastq/*_1*.fastq.gz \
      | sed 's/_1.*.fastq.gz//' \
      | sort > data/breseq/breseq_samples.txt

Check:

    wc -l data/breseq/breseq_samples.txt
    head data/breseq/breseq_samples.txt


-------------------------------------------------------------
4) Submit breseq (Slurm array)
------------------------------------------------------------

IMPORTANT:
- You do NOT edit the slurm script.
- You MUST provide the reference .gbk path.
- You MUST have already created:
      data/breseq/breseq_samples.txt

From cluster login node:

    cd ~/wgs_pipeline

Set your reference path (example):

    REF_GBK=/scratch/$USER/wgs_pipeline/data/breseq/ref/REL606.gbk

Submit the array job:

    sbatch \
      --export=ALL,REF_GBK="$REF_GBK",BRESEQ_SAMPLES="data/breseq/breseq_samples.txt",OUT_ROOT="results/breseq" \
      --array=1-$(wc -l < data/breseq/breseq_samples.txt) \
      02_breseq/cluster/slurm/run_breseq_array.slurm

You will see:

    Submitted batch job <JOBID>

Write down the JOBID.

------------------------------------------------------------
5) Monitor jobs
------------------------------------------------------------

Check queue:

    squeue -u $USER

Log files are stored in:

    results/slurm-breseq-<JOBID>_<TASKID>.out
    results/slurm-breseq-<JOBID>_<TASKID>.err

List recent logs:

    ls -1 results/slurm-breseq-*.out | tail
    ls -1 results/slurm-breseq-*.err | tail

View one log file (replace with actual filename):

    tail -n 50 results/slurm-breseq-<JOBID>_<TASKID>.err

After completion:

    sacct -j <jobid> --format=JobID,State,Elapsed,MaxRSS

------------------------------------------------------------
6) Check breseq outputs
------------------------------------------------------------

Each sample produces:

    results/breseq/<sample>/output/output.gd
    results/breseq/<sample>/output/index.html

Quick check:

    find results/breseq -name "output.gd" | head
    find results/breseq -name "index.html" | head

If these files exist, breseq ran correctly.

------------------------------------------------------------
7) Generate gd_list.txt (after ALL samples finish)
------------------------------------------------------------

From repo root:

    cd ~/wgs_pipeline

Create the GD list:

    OUT=results/breseq
    find "$OUT" -type f -path "*/output/output.gd" | sort > "$OUT/gd_list.txt"

Check:

    wc -l "$OUT/gd_list.txt"

The number should match your number of samples.


------------------------------------------------------------
8) Compare mutations across samples (gdtools COMPARE + ANNOTATE)
------------------------------------------------------------

IMPORTANT:
- Only run this AFTER breseq finished for all samples.
- This step uses the SAME reference .gbk file.
- This step runs on the cluster via Slurm.

From repo root on cluster:

    cd ~/wgs_pipeline

(Recommended) Confirm breseq outputs exist:

    find results/breseq -name "output.gd" | head

Set your reference path:

    REF_GBK=/scratch/$USER/wgs_pipeline/data/breseq/ref/<YOUR_REFERENCE>.gbk

Submit the compare job:

    sbatch --export=ALL,REF_GBK="$REF_GBK" 02_breseq/cluster/slurm/run_breseq_compare.slurm

Logs are written to:

    results/breseq/logs/breseq_compare-<jobid>.out
    results/breseq/logs/breseq_compare-<jobid>.err

Outputs are written to:

    results/breseq/gd_list.txt
    results/breseq/breseq_compare.tsv
    results/breseq/annotated_tsv/

Check:

    wc -l results/breseq/gd_list.txt
    ls -lh results/breseq/breseq_compare.tsv
    ls -lh results/breseq/annotated_tsv | head
	
------------------------------------------------------------
9) Copy results back to your local machine
------------------------------------------------------------

Run from your laptop:

    rsync -avz --progress \
      <user>@cluster.s3it.uzh.ch:/scratch/<user>/wgs_pipeline/results/breseq/ \
      <DESTINATION_FOLDER>/breseq_results/


------------------------------------------------------------
10) Cleanup (ONLY if you are sure)
------------------------------------------------------------

    rm -rf /scratch/$USER/wgs_pipeline/data/breseq/*
    rm -rf /scratch/$USER/wgs_pipeline/results/breseq/*