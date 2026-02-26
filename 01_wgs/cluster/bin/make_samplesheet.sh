#!/usr/bin/env bash
set -euo pipefail

DATA_DIR="${1:-data}"
OUT_TSV="${2:-samples.tsv}"

EXCLUDE_REGEX="${EXCLUDE_REGEX:-(_U1|_U2|untrimmed)}"
# IMPORTANT: include _1_trimmed (with underscore!)
R1_REGEX="${R1_REGEX:-(_1_trimmed|_R1_001|_R1|_1)}"

if [ ! -d "$DATA_DIR" ]; then
  echo "ERROR: data directory not found: $DATA_DIR"
  exit 1
fi

mapfile -t r1_files < <(
  find "$DATA_DIR" -maxdepth 1 -type f \( -name "*.fastq" -o -name "*.fastq.gz" \) \
  | grep -Eiv "$EXCLUDE_REGEX" \
  | grep -Ei "$R1_REGEX" \
  | sort
)

if [ ${#r1_files[@]} -eq 0 ]; then
  echo "ERROR: No R1 files found in $DATA_DIR matching R1_REGEX='$R1_REGEX' and excluding EXCLUDE_REGEX='$EXCLUDE_REGEX'"
  echo "Hint: put only intended FASTQs in $DATA_DIR or adjust R1_REGEX/EXCLUDE_REGEX."
  exit 1
fi

echo -e "sample\tr1\tr2" > "$OUT_TSV"

for r1 in "${r1_files[@]}"; do
  f=$(basename "$r1")

  # derive R2 name by common conventions
  r2="$r1"
  r2="${r2/_1_trimmed/_2_trimmed}"
  r2="${r2/_R1_001/_R2_001}"
  r2="${r2/_R1/_R2}"
  r2="${r2/_1./_2.}"

  if [ ! -f "$r2" ]; then
    echo "WARNING: Missing R2 for R1: $f  (expected: $(basename "$r2"))  -> skipping"
    continue
  fi

  sample="$f"
  sample="${sample%.fastq.gz}"
  sample="${sample%.fastq}"
  sample="${sample%_1_trimmed}"
  sample="${sample%_R1_001}"
  sample="${sample%_R1}"
  sample="${sample%_1}"

  echo -e "${sample}\t${r1}\t${r2}" >> "$OUT_TSV"
done

n=$(tail -n +2 "$OUT_TSV" | wc -l | tr -d ' ')
echo "Wrote $OUT_TSV with $n samples"
