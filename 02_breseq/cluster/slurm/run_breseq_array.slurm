#!/bin/bash
#SBATCH --job-name=breseq
#SBATCH --partition=standard
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --time=12:00:00
#SBATCH --output=results/slurm-breseq-%A_%a.out
#SBATCH --error=results/slurm-breseq-%A_%a.err

set -euo pipefail

module load miniforge3/25.3.0-3
source "$(conda info --base)/etc/profile.d/conda.sh"

cd "$SLURM_SUBMIT_DIR"
conda activate "$SLURM_SUBMIT_DIR/env/wgs"

# ensure output dir exists (results/ is a symlink to scratch after setup)
mkdir -p results/breseq

# run correct script path
bash 02_breseq/cluster/bin/breseq_one.sh
