#!/usr/bin/env bash
set -euo pipefail

OUT_ROOT="${OUT_ROOT:-results/breseq}"
REF_GBK="${REF_GBK:-}"
COMPARE_TSV="${COMPARE_TSV:-$OUT_ROOT/breseq_compare.tsv}"
ANN_DIR="${ANN_DIR:-$OUT_ROOT/annotated_tsv}"
LONG_TSV="${LONG_TSV:-$OUT_ROOT/breseq_all_samples_long.tsv}"

if [ -z "$REF_GBK" ]; then
  echo "ERROR: REF_GBK not set. Example:"
  echo "  REF_GBK=/path/to/reference.gbk OUT_ROOT=results/breseq bash breseq/cluster/bin/breseq_compare.sh"
  exit 1
fi
if [ ! -f "$REF_GBK" ]; then
  echo "ERROR: reference GBK not found: $REF_GBK"
  exit 1
fi

mkdir -p "$OUT_ROOT" "$ANN_DIR"

gd_list="$OUT_ROOT/gd_list.txt"
find "$OUT_ROOT" -type f -name "output.gd" | sort > "$gd_list"

if [ ! -s "$gd_list" ]; then
  echo "ERROR: No output.gd files found under $OUT_ROOT"
  exit 1
fi

echo "Found $(wc -l < "$gd_list") GD files."

if [[ ! -s "$COMPARE_TSV" ]]; then
  echo "Running gdtools COMPARE..."
  gdtools COMPARE -r "$REF_GBK" -f TSV -o "$COMPARE_TSV" $(cat "$gd_list")
else
  echo "Skipping COMPARE (exists): $COMPARE_TSV"
fi

while read -r gd; do
  sample=$(basename "$(dirname "$gd")")
  out_tsv="$ANN_DIR/$sample.tsv"

  if [[ -s "$out_tsv" ]]; then
    echo "Skipping ANNOTATE (exists): $out_tsv"
  else
    echo "Annotating: $sample"
    gdtools ANNOTATE -r "$REF_GBK" -f TSV -o "$out_tsv" "$gd"
  fi
done < "$gd_list"

first=$(ls "$ANN_DIR"/*.tsv | head -n 1)
echo -e "sample\t$(head -n 1 "$first")" > "$LONG_TSV"

for f in "$ANN_DIR"/*.tsv; do
  s=$(basename "$f" .tsv)
  tail -n +2 "$f" | sed "s/^/${s}\t/" >> "$LONG_TSV"
done

ls -lh "$LONG_TSV"
