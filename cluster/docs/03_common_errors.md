# Common errors and fixes

## 1) "module: command not found"
You are not on the cluster login node or your shell is not set up for modules.

Fix:
- log in again to the cluster
- try: `bash -l` (login shell)
- then: `module avail | head`

---

## 2) "Cannot open shared object file" / weird tool crashes
Usually caused by mixed environments or missing conda activation inside Slurm.

Fix:
- ensure the Slurm script contains:
  - `module load miniforge3/...`
  - `source "$(conda info --base)/etc/profile.d/conda.sh"`
  - `conda activate ~/wgs_pipeline/env/wgs`

---

## 3) "conda: command not found"
The conda module was not loaded.

Fix (login node):
    module load miniforge3/25.3.0-3
    which conda
    conda --version

---

## 4) Conda stuck at "Solving environment..."
This can take time.

Fixes:
- try again later (cluster load / solver load)
- if mamba is available, use it (faster solve):
    module load miniforge3/25.3.0-3
    mamba --version
  If mamba exists, tell the pipeline maintainer and we will switch setup to mamba.

---

## 5) "No files matching data/*_1_trimmed.fastq.gz found"
Your data folder is empty or naming is wrong.

Fix:
- check symlink:
    ls -lah ~/wgs_pipeline/data
- check scratch:
    ls -lah /scratch/$USER/wgs_pipeline/data
- confirm naming:
    ls -1 /scratch/$USER/wgs_pipeline/data/*_1_trimmed.fastq.gz | head

---

## 6) Missing R2 file (pipeline stops)
You have an R1 without a matching R2.

Fix:
- upload the missing *_2_trimmed.fastq.gz
- or remove the orphan R1 so the sample is not picked up

---

## 7) Slurm job pending forever
Common causes:
- wrong partition
- requesting too much memory/CPU
- user/account limits

Fix:
- check job reason:
    squeue -u $USER -o "%.18i %.9P %.8j %.8T %.10M %.6D %R"
- reduce resources (cpus/mem/time) if needed
- verify partition name used in the sbatch file

---

## 8) Job killed (TIMEOUT / OUT_OF_MEMORY)
Fix:
- increase #SBATCH --time or #SBATCH --mem in the slurm script
- re-submit job

---

## 9) "Permission denied" writing to results/
Results should go to scratch via the symlink.

Fix:
- verify symlink exists:
    ls -lah ~/wgs_pipeline/results
- verify scratch dir exists and is writable:
    mkdir -p /scratch/$USER/wgs_pipeline/results
    touch /scratch/$USER/wgs_pipeline/results/test_write && rm /scratch/$USER/wgs_pipeline/results/test_write

---

## 10) MultiQC report missing / empty
Usually FastQC didn’t run or wrote somewhere else.

Fix:
- check FastQC outputs:
    ls -lah ~/wgs_pipeline/results/fastqc_multiqc/fastqc | head
- check logs:
    ls -lah ~/wgs_pipeline/results/slurm-*.out
    ls -lah ~/wgs_pipeline/results/slurm-*.err

---

## 11) QUAST report.tsv missing
Usually assemblies weren’t created/copied.

Fix:
- check assemblies exist:
    ls -lah ~/wgs_pipeline/results/assemblies_for_qc/*.fasta | head
- check shovill outputs per sample:
    ls -lah ~/wgs_pipeline/results/*/shovill_out/contigs.fa 2>/dev/null | head

---

## 12) Prokka fails on some samples
Often due to empty/poor assemblies or unexpected contig formatting.

Fix:
- check the sample assembly:
    ls -lah ~/wgs_pipeline/results/assemblies_for_qc/<sample>.fasta
- check Prokka log:
    ls -lah ~/wgs_pipeline/results/<sample>/prokka_output.log
