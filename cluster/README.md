# Cluster setup + run (Slurm)

## 1) One-time setup (login node)
From the repo root on the cluster:

    bash cluster/bin/setup_cluster.sh

This will:
- create `~/wgs_pipeline/{scripts,env}`
- create `/scratch/$USER/wgs_pipeline/{data,results}`
- create conda env at `~/wgs_pipeline/env/wgs`
- symlink:
  - `~/wgs_pipeline/data -> /scratch/$USER/wgs_pipeline/data`
  - `~/wgs_pipeline/results -> /scratch/$USER/wgs_pipeline/results`

## 2) Add the pipeline script
Copy `WGS_pipelinev2.sh` into:

    ~/wgs_pipeline/scripts/WGS_pipelinev2.sh

Make executable:

    chmod +x ~/wgs_pipeline/scripts/WGS_pipelinev2.sh

## 3) Upload FASTQs to scratch
Put paired trimmed reads into:

    /scratch/$USER/wgs_pipeline/data/

## 4) Submit job

    cd ~/wgs_pipeline
    sbatch cluster/slurm/run_wgs.slurm

## 5) Monitor + logs

    squeue -u $USER
    ls -lah ~/wgs_pipeline/results
