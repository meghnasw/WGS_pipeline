#!/bin/bash
#SBATCH --job-name=breseq_compare
#SBATCH --partition=standard
#SBATCH --cpus-per-task=1
#SBATCH --mem=32G
#SBATCH --time=02:00:00
#SBATCH --output=results/breseq/logs/breseq_compare-%j.out
#SBATCH --error=results/breseq/logs/breseq_compare-%j.err

set -euo pipefail

module load miniforge3/25.3.0-3
source "$(conda info --base)/etc/profile.d/conda.sh"

cd "$SLURM_SUBMIT_DIR"
conda activate "$SLURM_SUBMIT_DIR/env/wgs"

OUT="results/breseq"
REF="${BRESEQ_REF:-}"
LIST="$OUT/gd_list.txt"

[ -f "$LIST" ] || { echo "ERROR: gd_list.txt not found. Create it with: bash 02_breseq/cluster/bin/make_gd_list.sh" >&2; exit 1; }
[ -f "$REF" ] || { echo "ERROR: ref file not found (set BRESEQ_REF): $REF" >&2; exit 1; }

mkdir -p "$OUT/annotated_tsv" "$OUT/logs"

gdtools COMPARE -r "$REF" -f TSV -o "$OUT/breseq_compare.tsv" $(cat "$LIST")

while read -r gd; do
  s=$(basename "$(dirname "$(dirname "$gd")")")
  gdtools ANNOTATE -r "$REF" -f TSV -o "$OUT/annotated_tsv/$s.tsv" "$gd"
done < "$LIST"