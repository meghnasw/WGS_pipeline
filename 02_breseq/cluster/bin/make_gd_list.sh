#!/usr/bin/env bash
set -euo pipefail

OUT="${1:-results/breseq}"
LIST="$OUT/gd_list.txt"

mkdir -p "$OUT"
find "$OUT" -type f -path "*/output/output.gd" | sort > "$LIST"

echo "Wrote: $LIST"
echo "N gd files: $(wc -l < "$LIST")"