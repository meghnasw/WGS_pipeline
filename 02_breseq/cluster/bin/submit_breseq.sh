#!/usr/bin/env bash
set -euo pipefail

# Usage:
# bash 02_breseq/cluster/bin/submit_breseq.sh --ref data/breseq/ref/myref.gbk [--samples data/breseq/breseq_samples.txt]

SAMPLES="${SAMPLES:-data/breseq/breseq_samples.txt}"
REF=""

PARTITION="${PARTITION:-standard}"
TIME="${TIME:-12:00:00}"
CPUS="${CPUS:-4}"
MEM="${MEM:-16G}"

while [ $# -gt 0 ]; do
  case "$1" in
    --ref) REF="$2"; shift 2 ;;
    --samples) SAMPLES="$2"; shift 2 ;;
    --partition) PARTITION="$2"; shift 2 ;;
    --time) TIME="$2"; shift 2 ;;
    --cpus) CPUS="$2"; shift 2 ;;
    --mem) MEM="$2"; shift 2 ;;
    -h|--help)
      echo "Usage: $0 --ref path/to/ref.gbk [--samples data/breseq/breseq_samples.txt] [--partition P] [--time T] [--cpus N] [--mem 16G]"
      exit 0
      ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

if [ -z "$REF" ]; then
  echo "ERROR: --ref is required (GenBank .gbk is strongly recommended)." >&2
  exit 1
fi

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$REPO_ROOT"

[ -f "$SAMPLES" ] || { echo "ERROR: samples file not found: $SAMPLES" >&2; exit 1; }
[ -f "$REF" ] || { echo "ERROR: ref file not found: $REF" >&2; exit 1; }

N=$(wc -l < "$SAMPLES" | tr -d ' ')
[ "$N" -gt 0 ] || { echo "ERROR: no lines in $SAMPLES" >&2; exit 1; }

mkdir -p results/breseq/logs

sbatch \
  --partition="$PARTITION" \
  --time="$TIME" \
  --cpus-per-task="$CPUS" \
  --mem="$MEM" \
  --array="1-$N" \
  --export=ALL,BRESEQ_SAMPLES="$SAMPLES",BRESEQ_REF="$REF" \
  02_breseq/cluster/slurm/run_breseq_array.slurm