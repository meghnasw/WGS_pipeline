#!/usr/bin/env bash
set -euo pipefail

SAMPLES_TSV="${SAMPLES_TSV:-samples.tsv}"
REF_GBK="${REF_GBK:-}"
OUT_ROOT="${OUT_ROOT:-results/breseq}"

if [ ! -f "$SAMPLES_TSV" ]; then
  echo "ERROR: samples.tsv not found: $SAMPLES_TSV"
  echo "Create it with: bash cluster/bin/make_samplesheet.sh data samples.tsv"
  exit 1
fi

if [ -z "$REF_GBK" ]; then
  echo "ERROR: REF_GBK not set. Provide it via the submit command."
  exit 1
fi

if [ ! -f "$REF_GBK" ]; then
  echo "ERROR: reference GBK not found: $REF_GBK"
  exit 1
fi

line=$(awk -v n="$SLURM_ARRAY_TASK_ID" 'NR==n+1{print; exit}' "$SAMPLES_TSV")
if [ -z "$line" ]; then
  echo "ERROR: No sample line for task id $SLURM_ARRAY_TASK_ID in $SAMPLES_TSV"
  exit 1
fi

sample=$(echo "$line" | awk -F'\t' '{print $1}')
r1=$(echo "$line" | awk -F'\t' '{print $2}')
r2=$(echo "$line" | awk -F'\t' '{print $3}')

if [ ! -f "$r1" ] || [ ! -f "$r2" ]; then
  echo "ERROR: missing FASTQ(s) for $sample"
  echo "R1: $r1"
  echo "R2: $r2"
  exit 1
fi

mkdir -p "$OUT_ROOT"

echo "Running breseq for: $sample"
breseq -j "${SLURM_CPUS_PER_TASK:-4}" \
  -r "$REF_GBK" \
  -o "$OUT_ROOT/$sample" \
  "$r1" "$r2"
