#!/bin/bash
#SBATCH --job-name=wgs_serial
#SBATCH --partition=standard
#SBATCH --cpus-per-task=8
#SBATCH --mem=24G
#SBATCH --time=10:00:00
#SBATCH --output=results/slurm-%j.out
#SBATCH --error=results/slurm-%j.err

set -euo pipefail

module load miniforge3/25.3.0-3

source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate "$HOME/wgs_pipeline/env/wgs"

cd "$HOME/wgs_pipeline"

bash ./scripts/WGS_pipelinev2.sh
