BRESEQ MODULE (cluster)

This is OPTIONAL. Use only if you want variant calls vs a reference genome.

Prereq:
- WGS repo is set up on cluster
- samples.tsv exists (made with make_samplesheet.sh)

1) Run breseq (one command)
    cd ~/wgs_pipeline
    bash breseq/cluster/bin/submit_breseq.sh --ref-gbk /path/to/reference.gbk --partition standard --time 12:00:00 --cpus 4 --mem 16G

Outputs:
- results/breseq/<sample>/
- results/breseq/logs/

2) Create combined TSV for plotting (one command)
    cd ~/wgs_pipeline
    REF_GBK=/path/to/reference.gbk OUT_ROOT=results/breseq bash breseq/cluster/bin/breseq_compare.sh

This creates:
- results/breseq/breseq_all_samples_long.tsv
zsh: parse error near `)'