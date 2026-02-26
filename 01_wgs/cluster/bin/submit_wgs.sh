#!/usr/bin/env bash
set -euo pipefail

# Defaults (easy starting point)
PARTITION="standard"
TIME="10:00:00"
CPUS="8"
MEM="24G"

# BUSCO defaults
BUSCO_LINEAGE=""  # e.g. bacteria_odb10 (required if you want BUSCO)
BUSCO_DOWNLOADS="/scratch/$USER/busco_downloads"

usage() {
  echo "Usage: $0 [--partition P] [--time HH:MM:SS] [--cpus N] [--mem 24G] [--busco-lineage LINEAGE] [--busco-downloads PATH]"
  echo
  echo "Example (with BUSCO):"
  echo "  $0 --partition standard --time 10:00:00 --cpus 8 --mem 24G --busco-lineage bacteria_odb10"
  echo
  echo "Example (no BUSCO):"
  echo "  $0 --partition standard --time 10:00:00 --cpus 8 --mem 24G"
}

while [ $# -gt 0 ]; do
  case "$1" in
    --partition) PARTITION="$2"; shift 2 ;;
    --time) TIME="$2"; shift 2 ;;
    --cpus) CPUS="$2"; shift 2 ;;
    --mem) MEM="$2"; shift 2 ;;
    --busco-lineage) BUSCO_LINEAGE="$2"; shift 2 ;;
    --busco-downloads) BUSCO_DOWNLOADS="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1"; usage; exit 1 ;;
  esac
done

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

mkdir -p results

echo "Submitting WGS pipeline with:"
echo "  partition: $PARTITION"
echo "  time:      $TIME"
echo "  cpus:      $CPUS"
echo "  mem:       $MEM"
if [ -n "$BUSCO_LINEAGE" ]; then
  echo "  BUSCO lineage:   $BUSCO_LINEAGE"
  echo "  BUSCO downloads: $BUSCO_DOWNLOADS"
else
  echo "  BUSCO: disabled (no --busco-lineage provided)"
fi

sbatch \
  --partition="$PARTITION" \
  --time="$TIME" \
  --cpus-per-task="$CPUS" \
  --mem="$MEM" \
  --export=ALL,LINEAGE="$BUSCO_LINEAGE",BUSCO_DOWNLOADS="$BUSCO_DOWNLOADS" \
  cluster/slurm/run_wgs.slurm
