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

mkdir -p results/breseq/logs results/breseq/annotated_tsv

REF="${REF_GBK:-}"
[ -n "$REF" ] || { echo "ERROR: REF_GBK not set. Submit with --export=ALL,REF_GBK=/path/to/ref.gbk" >&2; exit 1; }
[ -f "$REF" ] || { echo "ERROR: reference not found: $REF" >&2; exit 1; }

OUT="results/breseq"
GDLIST="$OUT/gd_list.txt"

# Create gd_list.txt if missing
if [[ ! -s "$GDLIST" ]]; then
  find "$OUT" -type f -path "*/output/output.gd" | sort > "$GDLIST"
fi

echo "Reference: $REF"
echo "GD list:   $GDLIST"
wc -l "$GDLIST" || true

# Must have at least 1 GD file
if [[ ! -s "$GDLIST" ]]; then
  echo "ERROR: gd_list.txt is empty. No output.gd files found under $OUT" >&2
  exit 1
fi

# Run COMPARE (one combined table)
gdtools COMPARE -r "$REF" -f TSV -o "$OUT/breseq_compare.tsv" $(cat "$GDLIST")

# Run ANNOTATE per sample
while read -r gd; do
  sample="$(basename "$(dirname "$(dirname "$gd")")")"
  out_tsv="$OUT/annotated_tsv/${sample}.tsv"
  gdtools ANNOTATE -r "$REF" -f TSV -o "$out_tsv" "$gd"
done < "$GDLIST"

echo "DONE:"
echo "  $OUT/breseq_compare.tsv"
echo "  $OUT/annotated_tsv/"
