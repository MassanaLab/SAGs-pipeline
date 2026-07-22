#!/usr/bin/env bash

set -euo pipefail

# =============================================================================
# STEP 19.1
#
# Calculate annotation and genomic-region statistics for each sample.
#
# For every sample, this script uses:
#   - A filter3 GFF3 file.
#   - Its corresponding filter3 assembly.
#
# The R script creates:
#   - <sample>_genomicregions1k.txt
#   - <sample>_genomicregions15k.txt
#   - <sample>_IntronCvsL.txt
#   - <sample>_long.annot.stats.pdf
#   - <sample>_long.annot.stats.RData
#
# Usage:
#   bash scripts/3-POST-BRAKER/\
#19.1-use_Extract_gff_info_out_Braker.sh [PROJECT]
#
# Example:
#   bash scripts/3-POST-BRAKER/\
#19.1-use_Extract_gff_info_out_Braker.sh coass_revisit
#
# Optional path overrides:
#
#   GFF_DIR=/path/to/final_gff3 \
#   FA_DIR=/path/to/assemblies3_clean \
#   bash scripts/3-POST-BRAKER/\
#19.1-use_Extract_gff_info_out_Braker.sh coass_revisit
#
# Set RESET_OUTPUT=1 to remove all previous results before starting.
# =============================================================================

W="${1:-coass_revisit}"

# Locate the repository independently of the current working directory.
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/../.." && pwd)"

# -----------------------------------------------------------------------------
# Input and output paths
# -----------------------------------------------------------------------------

R_SCRIPT="${SCRIPT_DIR}/Rscripts/Extract_gff_info_out_Braker.R"

NAMES_FILE="${NAMES_FILE:-${REPO_ROOT}/data/clean/names_${W}.txt}"

GFF_DIR="${GFF_DIR:-${REPO_ROOT}/data/clean/aleix_gff_process_big2_${W}_filter3/final_gff3}"

FA_DIR="${FA_DIR:-${REPO_ROOT}/data/clean/aleix_gff_process_big2_${W}_filter3/assemblies3_clean}"

OUT_DIR="${OUT_DIR:-${REPO_ROOT}/data/clean/${W}_annotation_stats}"

LOG_DIR="${LOG_DIR:-${REPO_ROOT}/data/logs/${W}_annotation_stats}"

RESET_OUTPUT="${RESET_OUTPUT:-0}"

# -----------------------------------------------------------------------------
# Check required programs and inputs
# -----------------------------------------------------------------------------

command -v Rscript >/dev/null 2>&1 || {
    echo "ERROR: Rscript is not available." >&2
    exit 1
}

[[ -f "$R_SCRIPT" ]] || {
    echo "ERROR: R script not found: $R_SCRIPT" >&2
    exit 1
}

[[ -f "$NAMES_FILE" ]] || {
    echo "ERROR: names file not found: $NAMES_FILE" >&2
    exit 1
}

[[ -d "$GFF_DIR" ]] || {
    echo "ERROR: GFF directory not found: $GFF_DIR" >&2
    exit 1
}

[[ -d "$FA_DIR" ]] || {
    echo "ERROR: FASTA directory not found: $FA_DIR" >&2
    exit 1
}

# -----------------------------------------------------------------------------
# Prepare output directories
# -----------------------------------------------------------------------------

# Do not delete the complete previous output unless explicitly requested.
if [[ "$RESET_OUTPUT" == "1" ]]; then
    echo "Removing previous outputs..."
    rm -rf -- "$OUT_DIR" "$LOG_DIR"
fi

mkdir -p "$OUT_DIR" "$LOG_DIR"

processed=0
missing=0
failed=0

# -----------------------------------------------------------------------------
# Process samples
# -----------------------------------------------------------------------------

while IFS= read -r sample || [[ -n "$sample" ]]; do

    # Remove a possible Windows carriage return.
    sample="${sample%$'\r'}"

    # Skip blank lines and comments in the sample list.
    [[ -z "$sample" || "$sample" == \#* ]] && continue

    gff="${GFF_DIR}/${sample}_filter3.gff3"
    fasta="${FA_DIR}/${sample}.fasta"

    sample_outdir="${OUT_DIR}/${sample}"

    stdout_log="${LOG_DIR}/${sample}.stdout.log"
    stderr_log="${LOG_DIR}/${sample}.stderr.log"

    echo
    echo "============================================================"
    echo "Processing sample: $sample"
    echo "GFF3:              $gff"
    echo "FASTA:             $fasta"
    echo "Output:            $sample_outdir"
    echo "============================================================"

    if [[ ! -s "$gff" ]]; then
        echo "WARNING: missing or empty GFF3; skipping: $gff" >&2
        ((missing += 1))
        continue
    fi

    if [[ ! -s "$fasta" ]]; then
        echo "WARNING: missing or empty FASTA; skipping: $fasta" >&2
        ((missing += 1))
        continue
    fi

    # Recreate this sample's output directory. This prevents files from an
    # older run from being confused with files generated in the current run.
    rm -rf -- "$sample_outdir"
    mkdir -p "$sample_outdir"

    if (
        cd "$sample_outdir"

        Rscript \
            "$R_SCRIPT" \
            "$sample" \
            "$gff" \
            "$fasta"

    ) >"$stdout_log" 2>"$stderr_log"; then

        # These are the two files required by step 19.2.
        regions_output="${sample_outdir}/${sample}_genomicregions1k.txt"
        intron_output="${sample_outdir}/${sample}_IntronCvsL.txt"

        if [[ -s "$regions_output" && -s "$intron_output" ]]; then
            echo "Done: $sample"
            ((processed += 1))
        else
            echo "ERROR: R finished but required outputs are missing: $sample" >&2
            ((failed += 1))
        fi

    else
        echo "ERROR: analysis failed for $sample" >&2
        echo "See log: $stderr_log" >&2
        ((failed += 1))
    fi

done < "$NAMES_FILE"

# -----------------------------------------------------------------------------
# Final report
# -----------------------------------------------------------------------------

echo
echo "============================================================"
echo "STEP 19.1 SUMMARY"
echo "============================================================"
echo "Successfully processed: $processed"
echo "Missing inputs:         $missing"
echo "Failed analyses:        $failed"
echo "Output directory:       $OUT_DIR"
echo "Log directory:          $LOG_DIR"

if ((missing > 0 || failed > 0)); then
    echo "ERROR: step 19.1 finished with missing or failed samples." >&2
    exit 1
fi

echo "Step 19.1 completed successfully."
