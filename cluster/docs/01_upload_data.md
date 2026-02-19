# Upload data to the cluster (scratch)

This pipeline expects paired trimmed FASTQs in the scratch data folder:

    /scratch/$USER/wgs_pipeline/data/

Required file naming:
- <sample>_1_trimmed.fastq.gz
- <sample>_2_trimmed.fastq.gz

Example:
- PSEU001_1_trimmed.fastq.gz
- PSEU001_2_trimmed.fastq.gz

---

## Recommended: rsync (fast + resumable)

Upload only trimmed paired reads:

    rsync -avP \
      --include="*_1_trimmed.fastq.gz" \
      --include="*_2_trimmed.fastq.gz" \
      --exclude="*" \
      /path/to/local/reads/ \
      <user>@cluster.s3it.uzh.ch:/scratch/<user>/wgs_pipeline/data/

Notes:
- Replace <user> with your cluster username
- If the transfer is interrupted, re-run the same command (rsync resumes)

---

## Alternative: scp (simple, not resumable)

    scp /path/to/*_trimmed.fastq.gz \
      <user>@cluster.s3it.uzh.ch:/scratch/<user>/wgs_pipeline/data/

---

## Verify upload on the cluster

    ls -lah /scratch/$USER/wgs_pipeline/data/
    ls -1 /scratch/$USER/wgs_pipeline/data/*_1_trimmed.fastq.gz | head
    ls -1 /scratch/$USER/wgs_pipeline/data/*_2_trimmed.fastq.gz | head

---

## Common mistakes
- Missing R2 file for a sample (e.g., only *_1_trimmed.fastq.gz uploaded)
- Wrong naming (e.g., _R1/_R2 instead of _1/_2)
- Uploading to home instead of scratch (slow + quota issues)

If naming differs, rename files to match the required pattern before running.
