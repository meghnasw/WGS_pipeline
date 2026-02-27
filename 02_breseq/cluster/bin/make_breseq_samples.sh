#!/usr/bin/env bash
set -euo pipefail

# Usage: bash 02_breseq/cluster/bin/make_breseq_samples.sh samples.tsv data/breseq/breseq_samples.txt
IN="${1:-samples.tsv}"
OUT="${2:-data/breseq/breseq_samples.txt}"

mkdir -p "$(dirname "$OUT")"

# samples.tsv expected (tab-separated):
# sample_id   r1_path   r2_path
# We convert to "prefix" by stripping _1.fastq.gz / _2.fastq.gz or _R1/_R2 patterns if present.
awk '
BEGIN{FS=OFS="\t"}
NR==1{next}
NF>=2{
  r1=$2
  gsub(/_1\.fastq\.gz$/,"",r1)
  gsub(/_R1\.fastq\.gz$/,"",r1)
  gsub(/\.fastq\.gz$/,"",r1)
  print r1
}' "$IN" > "$OUT"

echo "Wrote: $OUT"
echo "N prefixes: $(wc -l < "$OUT")"