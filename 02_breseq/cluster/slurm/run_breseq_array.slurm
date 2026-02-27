#!/bin/bash
#SBATCH --job-name=breseq
#SBATCH --output=results/breseq/logs/breseq-%A_%a.out
#SBATCH --error=results/breseq/logs/breseq-%A_%a.err

set -euo pipefail

module load miniforge3/25.3.0-3
source "$(conda info --base)/etc/profile.d/conda.sh"

cd "$SLURM_SUBMIT_DIR"
conda activate "$SLURM_SUBMIT_DIR/env/wgs"

bash 02_breseq/cluster/bin/breseq_one.sh