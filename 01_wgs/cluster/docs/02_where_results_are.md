# Where outputs and logs are written

The pipeline uses scratch for data + results via symlinks:

- ~/wgs_pipeline/data    -> /scratch/$USER/wgs_pipeline/data
- ~/wgs_pipeline/results -> /scratch/$USER/wgs_pipeline/results

So you can look in either location.

---

## Slurm logs

When you submit:

    sbatch cluster/slurm/run_wgs.slurm

Slurm writes logs here:

- results/slurm-<jobid>.out
- results/slurm-<jobid>.err

Example:

    ls -lah ~/wgs_pipeline/results/slurm-*.out
    ls -lah ~/wgs_pipeline/results/slurm-*.err

---

## WGS pipeline outputs (expected)

Your WGS script currently writes under:

- results/fastqc_multiqc/
  - fastqc/              (FastQC outputs)
  - multiqc/             (MultiQC report)

- results/assemblies_for_qc/
  - <sample>.fasta       (assemblies copied from Shovill)

- results/quast_multi/
  - report.tsv           (QUAST summary table)
  - report.html          (QUAST HTML report)

- results/<sample>/
  - shovill_out/         (Shovill assembly output)
  - prokka_out/          (Prokka annotation output)
  - benchmarking_*.log   (resource logs per step)

Also:
- benchmarking_all_steps.log (combined benchmarking summary)

---

## What to share / download after a run
For QC + summaries, these are usually enough:

- results/fastqc_multiqc/multiqc/multiqc_report.html
- results/quast_multi/report.tsv
- results/quast_multi/report.html
- results/assemblies_for_qc/   (assemblies)
- results/<sample>/prokka_out/ (annotations)
- benchmarking_all_steps.log

---

## Quick “is it done?” checks

Check QUAST report exists:

    test -f ~/wgs_pipeline/results/quast_multi/report.tsv && echo "QUAST OK" || echo "QUAST missing"

Check MultiQC report exists:

    ls -1 ~/wgs_pipeline/results/fastqc_multiqc/multiqc/*html

Count assemblies:

    ls -1 ~/wgs_pipeline/results/assemblies_for_qc/*.fasta | wc -l
