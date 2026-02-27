# 02_breseq (cluster)

This runs breseq as a **Slurm array** using the conda environment at `env/wgs`.

## Requirements

- You already set up the conda env (same one used by `01_wgs`):
	- `env/wgs` must contain `breseq` (and `gdtools`, which comes with breseq)
- You have reads on the cluster (FASTQ gz)
- You have a reference file on the cluster

Important: breseq works best with a **GenBank reference** (`.gbk`) that has annotations.
If you only have a FASTA, breseq can run, but annotation in outputs will be limited.

## Inputs

### 1) Reads
You can keep using the same `samples.tsv` as `01_wgs` (recommended).

`samples.tsv` format (tab-separated, header required):

sample_id    r1_path                   r2_path
S01          data/S01_1.fastq.gz        data/S01_2.fastq.gz

### 2) Reference (user-provided)
Users must copy the reference to the cluster (same way as the data), for example:

data/breseq/ref/my_reference.gbk

## Step 1 — Create breseq sample list

This module uses a simple “prefix list” (one prefix per line), like your original pipeline.
Generate it from `samples.tsv`:

bash 02_breseq/cluster/bin/make_breseq_samples.sh samples.tsv data/breseq/breseq_samples.txt

This creates lines like:
data/S01
data/S02
...

breseq then expects:
data/S01_1.fastq.gz and data/S01_2.fastq.gz

## Step 2 — Run breseq array

Submit with a user-provided reference:

bash 02_breseq/cluster/bin/submit_breseq.sh --ref data/breseq/ref/my_reference.gbk

Optional overrides:
--samples data/breseq/breseq_samples.txt
--partition standard
--time 12:00:00
--cpus 4
--mem 16G

Logs go to:
results/breseq/logs/

Outputs go to:
results/breseq/<sample>/...

## Step 3 — Create gd list

After array finishes:

bash 02_breseq/cluster/bin/make_gd_list.sh results/breseq

This creates:
results/breseq/gd_list.txt

## Step 4 — gdtools COMPARE + ANNOTATE

Run compare/annotate on the cluster (reference must be the same as used for breseq).
We pass it as an env var:

BRESEQ_REF=data/breseq/ref/my_reference.gbk sbatch 02_breseq/cluster/slurm/run_breseq_compare.slurm

This produces:
- results/breseq/breseq_compare.tsv
- results/breseq/annotated_tsv/<sample>.tsv

## Notes

- If breseq is missing, install into env/wgs:
  conda install -p env/wgs -y breseq