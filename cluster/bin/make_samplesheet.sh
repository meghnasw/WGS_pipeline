#!/usr/bin/env bash
set -euo pipefail

DATA_DIR="${1:-data}"
OUT_TSV="${2:-samples.tsv}"

# Exclude patterns: untrimmed reads must never be processed
EXCLUDE_REGEX="${EXCLUDE_REGEX:-(_U1|_U2|untrimmed)}"

# Recognize R1 patterns (we'll derive R2 by substitution)
# Supports: _1, _1_trimmed, _R1, _R1_001 (and .fastq/.fq or gz)
R1_REGEX="${R1_REGEX:-(_1_trimmed|_1|_R1_001|_R1)}"

if [ ! -d "$DATA_DIR" ]; then
  echo "ERROR: data directory not found: $DATA_DIR"
  exit 1
fi

# Find FASTQ/FASTQ.GZ/FQ/FQ.GZ
# -L follows symlinks (common on clusters)
# -maxdepth 3 catches data in one or two subfolders
mapfile -t r1_files < <(
  find -L "$DATA_DIR" -maxdepth 3 \
    \( -type f -o -type l \) \
    \( -name "*.fastq" -o -name "*.fastq.gz" -o -name "*.fq" -o -name "*.fq.gz" \) \
  | grep -Ev "$EXCLUDE_REGEX" \
  | grep -E "$R1_REGEX" \
  | sort
)

if [ ${#r1_files[@]} -eq 0 ]; then
  echo "ERROR: No R1 files found in $DATA_DIR matching R1_REGEX='$R1_REGEX' and excluding EXCLUDE_REGEX='$EXCLUDE_REGEX'"
  echo "Common causes:"
  echo "  - files are not fastq/fq (or gz)"
  echo "  - unexpected naming (R1 not in {_1_trimmed,_1,_R1,_R1_001})"
  echo "Fix:"
  echo "  - run with custom pattern, e.g.: R1_REGEX='(_R1_001|_R1)' bash cluster/bin/make_samplesheet.sh data samples.tsv"
  exit 1
fi

echo -e "sample\tr1\tr2" > "$OUT_TSV"

missing=0
pairs=0

for r1 in "${r1_files[@]}"; do
  base="$(basename "$r1")"

  # Derive R2 filename by common substitutions
  r2="$base"
  r2="${r2/_1_trimmed/_2_trimmed}"
  r2="${r2/_1./_2.}"
  r2="${r2/_R1_001/_R2_001}"
  r2="${r2/_R1./_R2.}"

  # Find R2 anywhere under DATA_DIR (handles subfolders)
  r2_path="$(find -L "$DATA_DIR" -maxdepth 3 \( -type f -o -type l \) -name "$r2" | head -n 1 || true)"

  # Derive sample name by stripping R1 marker + extension
  sample="$base"
  sample="$(echo "$sample" | sed -E \
    -e 's/_1_trimmed(\.(fastq|fq)(\.gz)?)$//' \
    -e 's/_1(\.(fastq|fq)(\.gz)?)$//' \
    -e 's/_R1_001(\.(fastq|fq)(\.gz)?)$//' \
    -e 's/_R1(\.(fastq|fq)(\.gz)?)$//' \
  )"

  if [ -z "$r2_path" ] || [ ! -e "$r2_path" ]; then
    echo "WARNING: Missing R2 for sample '$sample'"
    echo "  R1: $r1"
    echo "  Expected R2 filename: $r2"
    missing=$((missing+1))
    continue
  fi

  printf "%s\t%s\t%s\n" "$sample" "$r1" "$r2_path" >> "$OUT_TSV"
  pairs=$((pairs+1))
done

if [ "$pairs" -eq 0 ]; then
  echo "ERROR: Found R1 files but could not form any R1/R2 pairs."
  exit 1
fi

echo "Wrote $pairs pairs to $OUT_TSV"
if [ "$missing" -gt 0 ]; then
  echo "NOTE: $missing R1 files had missing R2 mates and were skipped."
fi