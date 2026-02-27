# 02_breseq (local)

This folder is for optional local inspection / plotting of breseq outputs.

Cluster outputs are in:
results/breseq/

Useful files:
- results/breseq/breseq_compare.tsv
- results/breseq/annotated_tsv/<sample>.tsv
- results/breseq/<sample>/output/ (breseq HTML + GD files)

Recommended workflow:
1) Run the cluster steps in `02_breseq/cluster/README.md`
2) Copy `results/breseq/` back to your local machine (or open it on the cluster)
3) Inspect:
   - breseq HTML reports inside each sample folder
   - compare/annotated TSVs for summaries