#!/bin/bash
#SBATCH --job-name=wgs
#SBATCH --output=results/slurm-%j.out
#SBATCH --error=results/slurm-%j.err

set -euo pipefail

module load miniforge3/25.3.0-3
source "$(conda info --base)/etc/profile.d/conda.sh"

cd "$SLURM_SUBMIT_DIR"
conda activate "$SLURM_SUBMIT_DIR/env/wgs"

bash scripts/WGS_pipelinev2.sh
