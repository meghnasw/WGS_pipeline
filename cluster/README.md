# Cluster setup + run (beginner)

## 1) One-time setup (login node)

Clone the repo:
    cd ~
    git clone git@github.com:meghnasw/WGS_pipeline.git wgs_pipeline
    cd wgs_pipeline

Run setup (creates conda env + scratch dirs + symlinks):
    PIPELINE_ROOT="$HOME/wgs_pipeline" SCRATCH_ROOT="/scratch/$USER/wgs_pipeline" bash cluster/bin/setup_cluster.sh

After setup:
- env:    ~/wgs_pipeline/env/wgs
- data:   ~/wgs_pipeline/data    -> /scratch/$USER/wgs_pipeline/data
- results:~/wgs_pipeline/results -> /scratch/$USER/wgs_pipeline/results

## 2) Upload reads
Put paired trimmed reads into:
    /scratch/$USER/wgs_pipeline/data/

Required naming:
- *_1_trimmed.fastq.gz
- *_2_trimmed.fastq.gz

## 3) Submit WGS pipeline (choose resources in the command)

From repo root:
    cd ~/wgs_pipeline
    bash cluster/bin/submit_wgs.sh --partition standard --time 10:00:00 --cpus 8 --mem 24G

## 4) Monitor + logs
    squeue -u $USER
    ls -lah ~/wgs_pipeline/results

Slurm logs:
- results/slurm-<jobid>.out
- results/slurm-<jobid>.err
