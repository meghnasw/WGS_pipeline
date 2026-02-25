#!/usr/bin/env bash
set -euo pipefail

PIPELINE_ROOT="${PIPELINE_ROOT:-$HOME/wgs_pipeline}"
SCRATCH_ROOT="${SCRATCH_ROOT:-/scratch/$USER/wgs_pipeline}"
CONDA_MODULE="${CONDA_MODULE:-miniforge3/25.3.0-3}"
ENV_PATH="${ENV_PATH:-$PIPELINE_ROOT/env/wgs}"

echo "[1/8] Creating directories..."
mkdir -p "$PIPELINE_ROOT"/{scripts,env}
mkdir -p "$SCRATCH_ROOT"/{data,results}

echo "[2/8] Loading conda module: $CONDA_MODULE"
module load "$CONDA_MODULE"
which conda
conda --version

echo "[3/8] Backing up and writing ~/.condarc"
if [ -f "$HOME/.condarc" ]; then
  cp -v "$HOME/.condarc" "$HOME/.condarc.bak.$(date +%Y%m%d_%H%M%S)"
fi

cat > "$HOME/.condarc" <<'EOC'
channels:
  - conda-forge
  - bioconda
  - defaults
channel_priority: strict
EOC

echo "[4/8] Creating conda environment at: $ENV_PATH"
conda create -y -p "$ENV_PATH" shovill quast prokka pigz fastqc multiqc busco

echo "[5/8] Making conda activate work in shells"
conda init bash || true

echo "[6/8] Creating scratch symlinks inside pipeline root..."
cd "$PIPELINE_ROOT"
[ -e data ] || ln -s "$SCRATCH_ROOT/data" data
[ -e results ] || ln -s "$SCRATCH_ROOT/results" results

echo "[7/8] Verifying tools..."
source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate "$ENV_PATH"

for tool in shovill quast prokka fastqc multiqc pigz; do
  echo -n " - $tool: "
  command -v "$tool" >/dev/null && echo "OK" || (echo "MISSING" && exit 1)
done

echo "[8/8] Done."
echo "Pipeline root : $PIPELINE_ROOT"
echo "Scratch root  : $SCRATCH_ROOT"
echo "Env path      : $ENV_PATH"
echo ""
echo "Next:"
echo "  copy WGS_pipelinev2.sh into: $PIPELINE_ROOT/scripts/"
echo "  upload FASTQs into: $SCRATCH_ROOT/data/"
echo "  submit: sbatch $PIPELINE_ROOT/cluster/slurm/run_wgs.slurm"
