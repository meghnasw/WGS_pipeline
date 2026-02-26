#!/usr/bin/env bash
set -euo pipefail

PARTITION="standard"
TIME="10:00:00"
CPUS="8"
MEM="24G"
BUSCO_LINEAGE=""
BUSCO_DOWNLOADS="/scratch/$USER/busco_downloads"

usage() {
  echo "Usage:"
  echo "  $0 --partition standard --time 10:00:00 --cpus 8 --mem 24G [--busco-lineage bacteria_odb10] [--busco-downloads /scratch/\$USER/busco_downloads]"
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

mkdir -p results

echo "Submitting WGS job:"
echo "  partition: $PARTITION"
echo "  time:      $TIME"
echo "  cpus:      $CPUS"
echo "  mem:       $MEM"
if [ -n "$BUSCO_LINEAGE" ]; then
  echo "  BUSCO:     ON ($BUSCO_LINEAGE)"
  echo "  downloads: $BUSCO_DOWNLOADS"
else
  echo "  BUSCO:     OFF"
fi

sbatch \
  --partition="$PARTITION" \
  --time="$TIME" \
  --cpus-per-task="$CPUS" \
  --mem="$MEM" \
  --export=ALL,BUSCO_LINEAGE="$BUSCO_LINEAGE",BUSCO_DOWNLOADS="$BUSCO_DOWNLOADS" \
  01_wgs/cluster/slurm/run_wgs.slurm
