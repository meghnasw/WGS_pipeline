#!/usr/bin/env bash
set -euo pipefail

PARTITION="standard"
TIME="12:00:00"
CPUS="4"
MEM="16G"
SAMPLES_TSV="samples.tsv"
REF_GBK=""
OUT_ROOT="results/breseq"

usage() {
  echo "Usage:"
  echo "  $0 --ref-gbk /path/to/reference.gbk [--samples samples.tsv] [--out results/breseq] [--partition P] [--time HH:MM:SS] [--cpus N] [--mem 16G]"
  echo
  echo "Example:"
  echo "  $0 --ref-gbk data/ref/PAO1.gbk --cpus 4 --mem 16G --time 12:00:00"
}

while [ $# -gt 0 ]; do
  case "$1" in
    --partition) PARTITION="$2"; shift 2 ;;
    --time) TIME="$2"; shift 2 ;;
    --cpus) CPUS="$2"; shift 2 ;;
    --mem) MEM="$2"; shift 2 ;;
    --samples) SAMPLES_TSV="$2"; shift 2 ;;
    --ref-gbk) REF_GBK="$2"; shift 2 ;;
    --out) OUT_ROOT="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1"; usage; exit 1 ;;
  esac
done

if [ -z "$REF_GBK" ]; then
  echo "ERROR: --ref-gbk is required"
  usage
  exit 1
fi

if [ ! -f "$SAMPLES_TSV" ]; then
  echo "ERROR: samples.tsv not found: $SAMPLES_TSV"
  echo "Create it with: bash cluster/bin/make_samplesheet.sh data samples.tsv"
  exit 1
fi

# Count samples (excluding header)
n=$(tail -n +2 "$SAMPLES_TSV" | awk -F'\t' 'NF>=3 && $1!="" {c++} END{print c+0}')
if [ "$n" -eq 0 ]; then
  echo "ERROR: No samples found in $SAMPLES_TSV"
  exit 1
fi

mkdir -p results/breseq/logs

echo "Submitting breseq array job:"
echo "  samples:    $n"
echo "  ref:        $REF_GBK"
echo "  out:        $OUT_ROOT"
echo "  partition:  $PARTITION"
echo "  time:       $TIME"
echo "  cpus:       $CPUS"
echo "  mem:        $MEM"

sbatch \
  --partition="$PARTITION" \
  --time="$TIME" \
  --cpus-per-task="$CPUS" \
  --mem="$MEM" \
  --array=1-"$n" \
  --export=ALL,SAMPLES_TSV="$SAMPLES_TSV",REF_GBK="$REF_GBK",OUT_ROOT="$OUT_ROOT" \
  cluster/breseq/slurm/run_breseq_array.slurm
