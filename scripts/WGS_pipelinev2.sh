#!/bin/bash
set -euo pipefail

echo "Starting WGS Pipeline for multiple samples"
echo "Order: FastQC+MultiQC -> Shovill (per sample) -> QUAST (all) -> Prokka (per sample)"
echo "================================================================="

mkdir -p results/fastqc_multiqc
mkdir -p results/assemblies_for_qc
mkdir -p results/quast_multi

# Build samples array from the input files
mapfile -t samples < <(ls -1 data/*_1_trimmed.fastq.gz 2>/dev/null | sed 's/.*\///' | sed 's/_1_trimmed.fastq.gz//' | sort -u)

if [ ${#samples[@]} -eq 0 ]; then
  echo "ERROR: No files matching data/*_1_trimmed.fastq.gz found"
  exit 1
fi

echo "Found ${#samples[@]} samples:"
printf ' - %s\n' "${samples[@]}"

########################################
# 0) FastQC + MultiQC (all FASTQs)
########################################
echo
echo "############################################"
echo "Running FastQC on all trimmed FASTQs"
echo "############################################"

# Collect all FASTQs (R1 and R2) that exist
mapfile -t fastqs < <(ls -1 data/*_trimmed.fastq.gz 2>/dev/null || true)

if [ ${#fastqs[@]} -eq 0 ]; then
  echo "ERROR: No files matching data/*_trimmed.fastq.gz found"
  exit 1
fi

# Run FastQC (uses multiple threads)
# Output goes into results/fastqc_multiqc/fastqc/
mkdir -p results/fastqc_multiqc/fastqc

/usr/bin/time -v -o results/fastqc_multiqc/benchmarking_fastqc.log \
  fastqc -t "${SLURM_CPUS_PER_TASK:-4}" -o results/fastqc_multiqc/fastqc "${fastqs[@]}" \
  > results/fastqc_multiqc/fastqc_stdout.log 2>&1

echo
echo "############################################"
echo "Running MultiQC to summarize FastQC"
echo "############################################"

# MultiQC report goes into results/fastqc_multiqc/multiqc/
mkdir -p results/fastqc_multiqc/multiqc

/usr/bin/time -v -o results/fastqc_multiqc/benchmarking_multiqc.log \
  multiqc results/fastqc_multiqc/fastqc -o results/fastqc_multiqc/multiqc \
  > results/fastqc_multiqc/multiqc_stdout.log 2>&1

########################################
# 1) Shovill per sample
########################################
for sample in "${samples[@]}"; do
  R1="data/${sample}_1_trimmed.fastq.gz"
  R2="data/${sample}_2_trimmed.fastq.gz"

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

/usr/bin/time -v -o "benchmarking_quast_multi.log" \
  quast results/assemblies_for_qc/*.fasta -o results/quast_multi \
  > "quast_multi_output.log" 2>&1

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
           --prefix "$sample" --force\
           "$CONTIGS" \
    > "results/${sample}/prokka_output.log" 2>&1
done

########################################
# 4) Combined benchmarking log
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
    echo
  } >> benchmarking_all_steps.log
done

{
  echo "======================================"
  echo "Benchmarking summary for QUAST (all samples)"
  echo "======================================"
  [ -f benchmarking_quast_multi.log ] && cat benchmarking_quast_multi.log || echo "No quast log"
  echo
} >> benchmarking_all_steps.log

echo "================================================================="
echo " All samples processed!"
echo " FastQC outputs            -> results/fastqc_multiqc/fastqc/"
echo " MultiQC report            -> results/fastqc_multiqc/multiqc/"
echo " Combined benchmarking     -> benchmarking_all_steps.log"
echo " Multi-sample QUAST report -> results/quast_multi/"
echo "================================================================="

