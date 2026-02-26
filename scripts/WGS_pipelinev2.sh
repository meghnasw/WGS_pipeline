#!/bin/bash
set -euo pipefail

echo "Starting WGS Pipeline for multiple samples"
echo "Order: FastQC+MultiQC -> Shovill (per sample) -> QUAST (all) -> Prokka (per sample) -> BUSCO (per assembly)"
echo "================================================================="

mkdir -p results/fastqc_multiqc
mkdir -p results/assemblies_for_qc
mkdir -p results/quast_multi
mkdir -p results/busco

# -----------------------------
# Read samples.tsv
# -----------------------------
SAMPLES_TSV="${SAMPLES_TSV:-samples.tsv}"

if [ ! -f "$SAMPLES_TSV" ]; then
  echo "ERROR: samplesheet not found: $SAMPLES_TSV"
  echo "Create it with: bash 01_wgs/cluster/bin/make_samplesheet.sh data samples.tsv"
  exit 1
fi

# sample list
mapfile -t samples < <(tail -n +2 "$SAMPLES_TSV" | awk -F'\t' 'NF>=3 && $1!="" {print $1}')

if [ ${#samples[@]} -eq 0 ]; then
  echo "ERROR: No samples found in $SAMPLES_TSV"
  exit 1
fi

echo "Found ${#samples[@]} samples:"
printf ' - %s\n' "${samples[@]}"

# fastq list for FastQC (R1+R2)
mapfile -t fastqs < <(tail -n +2 "$SAMPLES_TSV" | awk -F'\t' 'NF>=3 {print $2; print $3}')

if [ ${#fastqs[@]} -eq 0 ]; then
  echo "ERROR: No FASTQ paths found in $SAMPLES_TSV"
  exit 1
fi

echo
echo "======================================"
echo "Tool versions"
echo "======================================"
fastqc --version 2>/dev/null || true
multiqc --version 2>/dev/null || true
shovill --version 2>/dev/null || true
quast --version 2>/dev/null || true
prokka --version 2>/dev/null || true
busco --version 2>/dev/null || true
echo "BUSCO lineage: ${LINEAGE:-<not set>}"
echo "BUSCO downloads: ${BUSCO_DOWNLOADS:-<not set>}"
echo "======================================"

########################################
# 0) FastQC + MultiQC (all FASTQs)
########################################
echo
echo "############################################"
echo "Running FastQC on FASTQs from $SAMPLES_TSV"
echo "############################################"

mkdir -p results/fastqc_multiqc/fastqc

/usr/bin/time -v -o results/fastqc_multiqc/benchmarking_fastqc.log \
  fastqc -t "${SLURM_CPUS_PER_TASK:-4}" -o results/fastqc_multiqc/fastqc "${fastqs[@]}" \
  > results/fastqc_multiqc/fastqc_stdout.log 2>&1

echo
echo "############################################"
echo "Running MultiQC to summarize FastQC"
echo "############################################"

mkdir -p results/fastqc_multiqc/multiqc

/usr/bin/time -v -o results/fastqc_multiqc/benchmarking_multiqc.log \
  multiqc results/fastqc_multiqc/fastqc -o results/fastqc_multiqc/multiqc \
  > results/fastqc_multiqc/multiqc_stdout.log 2>&1

########################################
# 1) Shovill per sample
########################################
for sample in "${samples[@]}"; do
  R1=$(awk -F'\t' -v s="$sample" 'NR>1 && $1==s {print $2; exit}' "$SAMPLES_TSV")
  R2=$(awk -F'\t' -v s="$sample" 'NR>1 && $1==s {print $3; exit}' "$SAMPLES_TSV")

  if [ -z "$R1" ] || [ -z "$R2" ]; then
    echo "ERROR: Could not find R1/R2 for sample $sample in $SAMPLES_TSV"
    exit 1
  fi
  if [ ! -f "$R1" ]; then
    echo "ERROR: Missing R1 file for sample $sample: $R1"
    exit 1
  fi
  if [ ! -f "$R2" ]; then
    echo "ERROR: Missing R2 file for sample $sample: $R2"
    exit 1
  fi

  echo
  echo "############################################"
  echo "Running Shovill for sample: $sample"
  echo "############################################"

  mkdir -p "results/${sample}"

  /usr/bin/time -v -o "results/${sample}/benchmarking_shovill.log" \
    shovill --outdir "results/${sample}/shovill_out" \
            --R1 "$R1" \
            --R2 "$R2" \
            --cpus "${SLURM_CPUS_PER_TASK:-4}" \
    > "results/${sample}/shovill_output.log" 2>&1

  if [ -f "results/${sample}/shovill_out/contigs.fa" ]; then
    cp "results/${sample}/shovill_out/contigs.fa" "results/assemblies_for_qc/${sample}.fasta"
  else
    echo "WARNING: No contigs file found for ${sample}"
  fi
done

########################################
# 2) QUAST on all samples together
########################################
echo
echo "############################################"
echo "Running QUAST on all assemblies"
echo "############################################"

if ! ls results/assemblies_for_qc/*.fasta >/dev/null 2>&1; then
  echo "ERROR: No assemblies found in results/assemblies_for_qc/"
  exit 1
fi

/usr/bin/time -v -o "results/quast_multi/benchmarking_quast_multi.log" \
  quast results/assemblies_for_qc/*.fasta -o results/quast_multi \
  > "results/quast_multi/quast_multi_output.log" 2>&1

########################################
# 3) Prokka per sample
########################################
for sample in "${samples[@]}"; do
  echo
  echo "############################################"
  echo "Running Prokka for sample: $sample"
  echo "############################################"

  CONTIGS="results/assemblies_for_qc/${sample}.fasta"
  if [ ! -f "$CONTIGS" ]; then
    echo "WARNING: Missing contigs for $sample ($CONTIGS). Skipping Prokka."
    continue
  fi

  mkdir -p "results/${sample}/prokka_out"

  /usr/bin/time -v -o "results/${sample}/benchmarking_prokka.log" \
    prokka --outdir "results/${sample}/prokka_out" \
           --prefix "$sample" --force \
           --cpus "${SLURM_CPUS_PER_TASK:-4}" \
           "$CONTIGS" \
    > "results/${sample}/prokka_output.log" 2>&1
done

########################################
# 4) BUSCO per assembly
########################################
echo
echo "############################################"
echo "Running BUSCO on all assemblies"
echo "############################################"

# Required: set lineage (example bacteria_odb10). You can export before running:
#   export LINEAGE=bacteria_odb10
LINEAGE="${LINEAGE:-}"
BUSCO_RESULTS_DIR="results/busco"
BUSCO_LOG="$BUSCO_RESULTS_DIR/busco_run.log"
mkdir -p "$BUSCO_RESULTS_DIR"
: > "$BUSCO_LOG"

# Where BUSCO will download lineage datasets (default: scratch)
BUSCO_DOWNLOADS="${BUSCO_DOWNLOADS:-/scratch/$USER/busco_downloads}"
mkdir -p "$BUSCO_DOWNLOADS"

if [ -z "$LINEAGE" ]; then
  echo "WARNING: LINEAGE is not set. Skipping BUSCO."
  echo "Set it like: export LINEAGE=bacteria_odb10"
else
  for asm in results/assemblies_for_qc/*.fasta; do
    [[ -s "$asm" ]] || continue
    sample=$(basename "$asm" .fasta)

    outname="${sample}_busco"
    outdir="$BUSCO_RESULTS_DIR/$outname"

    # BUSCO creates a folder in out_path; treat existence as "already done"
    if [ -d "$outdir" ]; then
      echo "Skipping BUSCO (exists): $sample" | tee -a "$BUSCO_LOG"
      continue
    fi

    echo "Running BUSCO: $sample" | tee -a "$BUSCO_LOG"

    /usr/bin/time -v -o "$BUSCO_RESULTS_DIR/benchmarking_busco_${sample}.log" \
      busco -i "$asm" -l "$LINEAGE" -m genome \
            -o "$outname" --out_path "$BUSCO_RESULTS_DIR" \
            --cpu "${SLURM_CPUS_PER_TASK:-4}" \
            --download_path "$BUSCO_DOWNLOADS" \
      >>"$BUSCO_LOG" 2>&1
  done
fi

########################################
# 5) Combined benchmarking log
########################################
echo
echo "======================================"
echo "   Benchmarking summary (all steps)"
echo "======================================"

: > benchmarking_all_steps.log

{
  echo "======================================"
  echo "Benchmarking summary for FastQC"
  echo "======================================"
  [ -f results/fastqc_multiqc/benchmarking_fastqc.log ] && cat results/fastqc_multiqc/benchmarking_fastqc.log || echo "No fastqc log"
  echo
  echo "======================================"
  echo "Benchmarking summary for MultiQC"
  echo "======================================"
  [ -f results/fastqc_multiqc/benchmarking_multiqc.log ] && cat results/fastqc_multiqc/benchmarking_multiqc.log || echo "No multiqc log"
  echo
} >> benchmarking_all_steps.log

for sample in "${samples[@]}"; do
  {
    echo "======================================"
    echo "Benchmarking summary for $sample"
    echo "======================================"
    echo "--- Shovill ---"
    [ -f "results/${sample}/benchmarking_shovill.log" ] && cat "results/${sample}/benchmarking_shovill.log" || echo "No shovill log"
    echo
    echo "--- Prokka ---"
    [ -f "results/${sample}/benchmarking_prokka.log" ] && cat "results/${sample}/benchmarking_prokka.log" || echo "No prokka log"
    echo
    echo "--- BUSCO ---"
    [ -f "results/busco/benchmarking_busco_${sample}.log" ] && cat "results/busco/benchmarking_busco_${sample}.log" || echo "No busco log"
    echo
    echo
  } >> benchmarking_all_steps.log
done

{
  echo "======================================"
  echo "Benchmarking summary for QUAST (all samples)"
  echo "======================================"
  [ -f results/quast_multi/benchmarking_quast_multi.log ] && cat results/quast_multi/benchmarking_quast_multi.log || echo "No quast log"
  echo
} >> benchmarking_all_steps.log

echo "================================================================="
echo " All samples processed!"
echo " FastQC outputs            -> results/fastqc_multiqc/fastqc/"
echo " MultiQC report            -> results/fastqc_multiqc/multiqc/"
echo " Combined benchmarking     -> benchmarking_all_steps.log"
echo " Multi-sample QUAST report -> results/quast_multi/"
echo " BUSCO outputs             -> results/busco/"
echo "================================================================="