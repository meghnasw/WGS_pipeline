# breseq module (02_breseq)

This module runs **breseq** against a **user-provided reference** on the cluster, then supports local plotting/inspection.

Structure:

- `02_breseq/cluster/` — run breseq + gdtools on the cluster (Slurm + conda)
- `02_breseq/local/` — optional local visualization / inspection

Outputs are written to: `results/breseq/`

Start here:
- Cluster instructions: `02_breseq/cluster/README.md`
- Local instructions: `02_breseq/local/README.md`