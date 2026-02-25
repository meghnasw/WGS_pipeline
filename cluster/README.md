# WGS pipeline on the cluster (beginner workflow)

This pipeline runs on the S3IT cluster using Slurm + a conda env from the miniforge module.
Goal: beginners run as few commands as possible.

What it runs:
FastQC/MultiQC -> Shovill -> QUAST -> Prokka -> BUSCO (optional)

------------------------------------------------------------
0) One-time: clone the repo (on cluster login node)
------------------------------------------------------------

```bash
cd ~
git clone git@github.com:meghnasw/WGS_pipeline.git wgs_pipeline
cd wgs_pipeline

------------------------------------------------------------
1) One-time: cluster setup (env + scratch folders + symlinks)
------------------------------------------------------------

This creates:
- env:     ~/wgs_pipeline/env/wgs
- data:    ~/wgs_pipeline/data    -> /scratch/$USER/wgs_pipeline/data
- results: ~/wgs_pipeline/results -> /scratch/$USER/wgs_pipeline/results

Run:

PIPELINE_ROOT="$HOME/wgs_pipeline" SCRATCH_ROOT="/scratch/$USER/wgs_pipeline" bash cluster/bin/setup_cluster.sh


If setup worked, you should see:

ls -lah data results


------------------------------------------------------------
2) Upload data to the cluster (recommended: rsync)
------------------------------------------------------------

Data must be in:

/scratch/$USER/wgs_pipeline/data/

Allowed FASTQ formats:
- .fastq or .fastq.gz

Naming can be:
- *_1.fastq(.gz) and *_2.fastq(.gz)
- *_1_trimmed.fastq(.gz) and *_2_trimmed.fastq(.gz)
- *_R1.fastq(.gz) and *_R2.fastq(.gz)
- *_R1_001.fastq(.gz) and *_R2_001.fastq(.gz)

EXCLUDED (never processed):
- anything with _U1 or _U2
- anything containing "untrimmed"

Your lab’s sequencing data location (Mac/SMB mount):
smb://idnas32.d.uzh.ch/G_DQBM_GR_Rk$/sgr_rk
On Mac this usually appears as: /Volumes/sgr_rk/


Option A (recommended): rsync only paired reads to scratch
Example (copy only trimmed reads; adjust path as needed):

rsync -avP \
  --include="*_1_trimmed.fastq.gz" \
  --include="*_2_trimmed.fastq.gz" \
  --exclude="*" \
  /Volumes/sgr_rk/<PATH_TO_READS>/ \
  <user>@cluster.s3it.uzh.ch:/scratch/<user>/wgs_pipeline/data/


Option B: rsync all fastq/fastq.gz then filter via samplesheet (more flexible)
Example:

rsync -avP \
  --include="*.fastq" \
  --include="*.fastq.gz" \
  --exclude="*" \
  /Volumes/sgr_rk/<PATH_TO_READS>/ \
  <user>@cluster.s3it.uzh.ch:/scratch/<user>/wgs_pipeline/data/


Verify upload on cluster:

ls -lh /scratch/$USER/wgs_pipeline/data | head
ls -1 /scratch/$USER/wgs_pipeline/data/* | wc -l
ls /scratch/$USER/wgs_pipeline/data | grep '_U' || echo "No U files found"


------------------------------------------------------------
3) Create samples.tsv (auto-detect correct pairs; excludes _U1/_U2/untrimmed)
------------------------------------------------------------

From repo root on cluster:

cd ~/wgs_pipeline
bash cluster/bin/make_samplesheet.sh data samples.tsv

Inspect:

head -n 5 samples.tsv
wc -l samples.tsv

(samples.tsv includes a header line; number of samples = lines - 1)


------------------------------------------------------------
4) Submit the pipeline (resources + BUSCO all from ONE command)
------------------------------------------------------------

IMPORTANT:
- You do not edit the slurm script.
- You set resources in the submit command.
- BUSCO is enabled by providing --busco-lineage.

Example with BUSCO (recommended):

cd ~/wgs_pipeline
bash cluster/bin/submit_wgs.sh \
  --partition standard \
  --time 10:00:00 \
  --cpus 8 \
  --mem 24G \
  --busco-lineage bacteria_odb10

BUSCO downloads will go to:
  /scratch/$USER/busco_downloads
(you can override with: --busco-downloads /scratch/$USER/somewhere)


Example without BUSCO:

bash cluster/bin/submit_wgs.sh --partition standard --time 10:00:00 --cpus 8 --mem 24G


------------------------------------------------------------
5) Monitor the job + logs
------------------------------------------------------------

squeue -u $USER

Slurm logs are written to:
- results/slurm-<jobid>.out
- results/slurm-<jobid>.err

Follow logs:

tail -f results/slurm-<jobid>.out
tail -f results/slurm-<jobid>.err

Check resources after completion:

sacct -j <jobid> --format=JobID,State,Elapsed,MaxRSS,ReqMem,AllocCPUS


------------------------------------------------------------
6) Outputs (on scratch via symlink)
------------------------------------------------------------

Key outputs:
- results/fastqc_multiqc/multiqc/          (MultiQC report)
- results/assemblies_for_qc/<sample>.fasta (assemblies)
- results/quast_multi/                     (QUAST report)
- results/<sample>/prokka_out/             (Prokka outputs)
- results/busco/                           (BUSCO outputs, if enabled)
- benchmarking_all_steps.log               (combined benchmarking summary)


------------------------------------------------------------
7) Copy results back to your local/server storage
------------------------------------------------------------

Option A: copy entire results folder back to your local machine:
(run from your laptop)

rsync -avz --progress \
  <user>@cluster.s3it.uzh.ch:/scratch/<user>/wgs_pipeline/results/ \
  /Volumes/sgr_rk/<DESTINATION_FOLDER>/results/


Option B: copy only key summaries (faster):
(run from your laptop)

rsync -avz --progress \
  <user>@cluster.s3it.uzh.ch:/scratch/<user>/wgs_pipeline/results/fastqc_multiqc/multiqc/ \
  /Volumes/sgr_rk/<DESTINATION_FOLDER>/multiqc/

rsync -avz --progress \
  <user>@cluster.s3it.uzh.ch:/scratch/<user>/wgs_pipeline/results/quast_multi/ \
  /Volumes/sgr_rk/<DESTINATION_FOLDER>/quast_multi/

rsync -avz --progress \
  <user>@cluster.s3it.uzh.ch:/scratch/<user>/wgs_pipeline/results/assemblies_for_qc/ \
  /Volumes/sgr_rk/<DESTINATION_FOLDER>/assemblies_for_qc/

rsync -avz --progress \
  <user>@cluster.s3it.uzh.ch:/scratch/<user>/wgs_pipeline/results/busco/ \
  /Volumes/sgr_rk/<DESTINATION_FOLDER>/busco/  2>/dev/null || true


------------------------------------------------------------
8) Cleanup (only when you are SURE you no longer need files on scratch)
------------------------------------------------------------

rm -rf /scratch/$USER/wgs_pipeline/data/*
rm -rf /scratch/$USER/wgs_pipeline/results/*
