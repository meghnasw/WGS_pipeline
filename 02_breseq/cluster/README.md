# 02_breseq on the cluster

This runs breseq as a **Slurm array** using the conda environment at `env/wgs`.

------------------------------------------------------------
Requirements
------------------------------------------------------------

- You already set up the conda env (same one used by `01_wgs`):
	- `env/wgs` must contain `breseq` (and `gdtools`, which comes with breseq)
- You have reads on the cluster (FASTQ gz)
- You have a reference file on the cluster

Important: breseq works best with a **GenBank reference** (`.gbk`) that has annotations.
If you only have a FASTA, breseq can run, but annotation in outputs will be limited.


------------------------------------------------------------
Inputs

1) Reads

You can keep using the same `samples.tsv` as `01_wgs` (recommended).

`samples.tsv` format (tab-separated, header required):

sample_id    r1_path                   r2_path
S01          data/S01_1.fastq.gz        data/S01_2.fastq.gz

2) Reference (user-provided)
Users must copy the reference to the cluster (same way as the data), for example:

data/breseq/ref/my_reference.gbk


------------------------------------------------------------
0) One-time assumption
------------------------------------------------------------

You already completed the WGS cluster setup.

If not, FIRST follow:
01_wgs/cluster/README.md

breseq uses the SAME folders created during WGS setup:

env:     ~/wgs_pipeline/env/wgs
data:    ~/wgs_pipeline/data    -> /scratch/$USER/wgs_pipeline/data
results: ~/wgs_pipeline/results -> /scratch/$USER/wgs_pipeline/results

Make sure breseq is installed in the env:

```bash
    module load miniforge3/25.3.0-3
    source "$(conda info --base)/etc/profile.d/conda.sh"
    conda install -p ~/wgs_pipeline/env/wgs -y breseq
```

------------------------------------------------------------
1) Upload your reference file to the cluster
------------------------------------------------------------

breseq requires a reference genome.

Recommended format:
- .gbk (GenBank, annotated)

Create a reference folder on the cluster:

```bash
    mkdir -p /scratch/$USER/wgs_pipeline/data/breseq/ref
```

Upload the reference from your laptop:

```bash
    scp my_reference.gbk <user>@cluster.s3it.uzh.ch:/scratch/<user>/wgs_pipeline/data/breseq/ref/
```

Verify upload (on cluster):

```bash
    ls /scratch/$USER/wgs_pipeline/data/breseq/ref/
```

IMPORTANT:
You must use the SAME reference file for:
- breseq
- gdtools COMPARE
- gdtools ANNOTATE


------------------------------------------------------------
2) Create breseq sample list
------------------------------------------------------------

breseq uses a simple prefix list like:

data/S01
data/S02
data/S03

If you already created samples.tsv during WGS:

```bash
    cd ~/wgs_pipeline
    bash 02_breseq/cluster/bin/make_breseq_samples.sh samples.tsv data/breseq/breseq_samples.txt
```

Check the file:

```bash
    wc -l data/breseq/breseq_samples.txt
    head data/breseq/breseq_samples.txt
```

Each prefix must correspond to:

<prefix>_1.fastq.gz
<prefix>_2.fastq.gz

------------------------------------------------------------
3) Submit breseq (Slurm array job)
------------------------------------------------------------

IMPORTANT:

- Each sample runs as one array task.
- You DO NOT edit the slurm script.
- You set resources in the submit command.
- You MUST provide the reference file.

Suggested resources (bacterial WGS):

1–20 samples:
    --cpus 4
    --mem 16G
    --time 04:00:00

21–50 samples:
    --cpus 4
    --mem 16G
    --time 08:00:00

51–100 samples:
    --cpus 4
    --mem 16G
    --time 16:00:00

Submit example:

```bash
    cd ~/wgs_pipeline

    bash 02_breseq/cluster/bin/submit_breseq.sh \
        --ref data/breseq/ref/my_reference.gbk \
        --partition standard \
        --time 08:00:00 \
        --cpus 4 \
        --mem 16G
```

------------------------------------------------------------
4) Monitor the job
------------------------------------------------------------

Check queue:

```bash
    squeue -u $USER
```

Logs are written to:

```bash
    results/breseq/logs/
```

Follow a job:

```bash
    tail -f results/breseq/logs/breseq-<jobid>_<arrayid>.out
```

Check resource usage after completion:

```bash
    sacct -j <jobid> --format=JobID,State,Elapsed,MaxRSS,ReqMem,AllocCPUS
```

------------------------------------------------------------
5) Create gd_list.txt (after all samples finish)
------------------------------------------------------------

After the array job finishes:

```bash
    cd ~/wgs_pipeline
    bash 02_breseq/cluster/bin/make_gd_list.sh results/breseq
```

Check:

```bash
    wc -l results/breseq/gd_list.txt
```

This file lists all output.gd files.


------------------------------------------------------------
6) Run COMPARE + ANNOTATE
------------------------------------------------------------

IMPORTANT:
Use the SAME reference file as in step 3.

Submit:

```bash
    cd ~/wgs_pipeline

    BRESEQ_REF=data/breseq/ref/my_reference.gbk \
    sbatch 02_breseq/cluster/slurm/run_breseq_compare.slurm
```

This generates:

    results/breseq/breseq_compare.tsv
    results/breseq/annotated_tsv/<sample>.tsv


------------------------------------------------------------
7) Outputs
------------------------------------------------------------

Per sample:

    results/breseq/<sample>/

Important files:

    output/output.gd
    output/index.html

Combined outputs:

    results/breseq/breseq_compare.tsv
    results/breseq/annotated_tsv/


------------------------------------------------------------
8) Copy results back to your local machine
------------------------------------------------------------

Run from your laptop:

```bash
    rsync -avz --progress \
        <user>@cluster.s3it.uzh.ch:/scratch/<user>/wgs_pipeline/results/breseq/ \
        <DESTINATION_FOLDER>/breseq_results/
```

------------------------------------------------------------
9) Cleanup (ONLY if you are sure)
------------------------------------------------------------

```bash
    rm -rf /scratch/$USER/wgs_pipeline/results/breseq/*
    rm -rf /scratch/$USER/wgs_pipeline/data/breseq/*
```

------------------------------------------------------------
10) Local visualization
------------------------------------------------------------

Follow:

    02_breseq/local/README.md