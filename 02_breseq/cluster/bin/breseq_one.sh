#!/usr/bin/env bash
set -euo pipefail

# Defaults (can be overridden when submitting)
BRESEQ_SAMPLES="${BRESEQ_SAMPLES:-data/breseq/breseq_samples.txt}"
OUT_ROOT="${OUT_ROOT:-results/breseq}"
REF_GBK="${REF_GBK:-}"

# Slurm array task required
: "${SLURM_ARRAY_TASK_ID:?ERROR: SLURM_ARRAY_TASK_ID not set (submit as an array job)}"

# Validate inputs
[ -f "$BRESEQ_SAMPLES" ] || { echo "ERROR: samples list not found: $BRESEQ_SAMPLES" >&2; exit 1; }
[ -n "$REF_GBK" ] || { echo "ERROR: REF_GBK not set. Submit with: --export=ALL,REF_GBK=/path/to/ref.gbk" >&2; exit 1; }
[ -f "$REF_GBK" ] || { echo "ERROR: reference not found: $REF_GBK" >&2; exit 1; }

prefix="$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$BRESEQ_SAMPLES")"
[ -n "$prefix" ] || { echo "ERROR: no prefix on line ${SLURM_ARRAY_TASK_ID} in $BRESEQ_SAMPLES" >&2; exit 1; }

sample="$(basename "$prefix")"
outdir="$OUT_ROOT/$sample"
mkdir -p "$outdir"

# FASTQ naming expected by this pipeline:
r1="${prefix}_1_trimmed.fastq.gz"
r2="${prefix}_2_trimmed.fastq.gz"

[ -f "$r1" ] || { echo "ERROR: missing R1: $r1" >&2; exit 1; }
[ -f "$r2" ] || { echo "ERROR: missing R2: $r2" >&2; exit 1; }

echo "Running breseq:"
echo "  sample     : $sample"
echo "  prefix     : $prefix"
echo "  ref (gbk)  : $REF_GBK"
echo "  r1         : $r1"
echo "  r2         : $r2"
echo "  outdir     : $outdir"
echo "  cpus       : ${SLURM_CPUS_PER_TASK:-1}"

breseq -j "${SLURM_CPUS_PER_TASK:-1}" \
  -r "$REF_GBK" \
  -o "$outdir" \
  "$r1" \
  "$r2"
