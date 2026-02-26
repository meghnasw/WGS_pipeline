#!/usr/bin/env bash
set -euo pipefail

# Example usage:
# bash local/metrics/example_run.sh /path/to/results

RESULTS="${1:-results}"
Rscript local/metrics/summarize_metrics.R "$RESULTS"
echo "Wrote: $RESULTS/combined_metrics.csv"