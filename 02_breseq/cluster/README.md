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


------------------------------------------------------------
4) Submit breseq array job
------------------------------------------------------------

From repo root on cluster:

    cd ~/wgs_pipeline

Submit:

    sbatch --array=1-$(wc -l < data/breseq/breseq_samples.txt) \
      02_breseq/cluster/slurm/run_breseq_array.slurm

This runs one sample per array task.

------------------------------------------------------------
5) Monitor jobs
------------------------------------------------------------

Check queue:

    squeue -u $USER

Check logs:

    ls results/breseq-*.out
    tail -f results/breseq-<jobid>_<taskid>.out

After completion:

    sacct -j <jobid> --format=JobID,State,Elapsed,MaxRSS


------------------------------------------------------------
6) Generate gd_list.txt (after all jobs finish)
------------------------------------------------------------

On cluster:

    OUT=/scratch/$USER/wgs_pipeline/results/breseq

    find "$OUT" -type f -path "*/output/output.gd" | sort > "$OUT/gd_list.txt"

Check:

    wc -l "$OUT/gd_list.txt"


------------------------------------------------------------
7) Run mutation comparison
------------------------------------------------------------

Submit comparison job:

    sbatch 02_breseq/cluster/breseq_compare.sbatch

This generates:

    results/breseq/breseq_compare.tsv
    results/breseq/annotated_tsv/


------------------------------------------------------------
8) Copy results back to your local machine
------------------------------------------------------------

From your laptop:

    rsync -avz --progress \
      <user>@cluster.s3it.uzh.ch:/scratch/<user>/wgs_pipeline/results/breseq/ \
      <DESTINATION_FOLDER>/breseq_results/


------------------------------------------------------------
9) Cleanup (only if you are sure)
------------------------------------------------------------

    rm -rf /scratch/$USER/wgs_pipeline/data/breseq/*
    rm -rf /scratch/$USER/wgs_pipeline/results/breseq/*