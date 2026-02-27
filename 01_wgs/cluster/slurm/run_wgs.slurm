#!/bin/bash
#SBATCH --job-name=wgs_serial
#SBATCH --output=results/slurm-%j.out
#SBATCH --error=results/slurm-%j.err

set -euo pipefail

module load miniforge3/25.3.0-3

# Make conda activate work in non-interactive shells (Slurm)
source "$(conda info --base)/etc/profile.d/conda.sh"

# Run from the directory where sbatch was submitted (repo root)
cd "$SLURM_SUBMIT_DIR"

# Activate env inside this repo clone
conda activate "$SLURM_SUBMIT_DIR/env/wgs"
cd wgs_pipeline
bash scripts/WGS_pipelinev2.sh
