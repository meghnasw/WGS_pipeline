#!/usr/bin/env bash
set -euo pipefail

SAMPLES="${BRESEQ_SAMPLES:-data/breseq/breseq_samples.txt}"
REF="${BRESEQ_REF:-}"

[ -n "${SLURM_ARRAY_TASK_ID:-}" ] || { echo "ERROR: SLURM_ARRAY_TASK_ID not set" >&2; exit 1; }
[ -f "$SAMPLES" ] || { echo "ERROR: samples file not found: $SAMPLES" >&2; exit 1; }
[ -f "$REF" ] || { echo "ERROR: ref file not found (set --ref in submit script): $REF" >&2; exit 1; }

prefix="$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$SAMPLES")"
[ -n "$prefix" ] || { echo "ERROR: no prefix for task id ${SLURM_ARRAY_TASK_ID}" >&2; exit 1; }

sample="$(basename "$prefix")"
outdir="results/breseq/$sample"
mkdir -p "$outdir"

breseq -j "${SLURM_CPUS_PER_TASK:-1}" \
  -r "$REF" \
  -o "$outdir" \
  "${prefix}_1.fastq.gz" \
  "${prefix}_2.fastq.gz"