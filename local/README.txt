LOCAL (run on your own computer)

This folder contains two local workflows:
- local/wgs   : WGS pipeline metrics + dashboard
- local/breseq: breseq plots

------------------------------------------------------------
WGS: 1) Create combined_metrics.csv
------------------------------------------------------------

Mac / Linux:
    Rscript local/wgs/metrics/summarize_metrics.R "/path/to/All_results"

Windows PowerShell:
    Rscript local\wgs\metrics\summarize_metrics.R "C:\path\to\All_results"

Output:
- <results_root>/combined_metrics.csv

------------------------------------------------------------
WGS: 2) Open the dashboard (Shiny)
------------------------------------------------------------

Mac / Linux:
    Rscript local/wgs/dashboard/run_dashboard.R "/path/to/All_results"

Windows PowerShell:
    Rscript local\wgs\dashboard\run_dashboard.R "C:\path\to\All_results"

The dashboard automatically looks for:
- <results_root>/combined_metrics.csv
- <results_root>/fastqc_multiqc/multiqc/multiqc_report.html (if present)

------------------------------------------------------------
BRESEQ: plots
------------------------------------------------------------

See:
- local/breseq/README.txt
