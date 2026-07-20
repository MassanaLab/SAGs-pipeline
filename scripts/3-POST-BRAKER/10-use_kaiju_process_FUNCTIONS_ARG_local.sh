#!/usr/bin/env bash

set -euo pipefail

# Usage:
#   bash scripts/coass_guigo/kaiju_process_filters_local.sh coass_guigo
#
# If no argument is given, use coass_guigo
W="${1:-coass_guigo}"

SAMPLES_FILE="data/clean/names_${W}.txt"

KAIJU_DIR="${HOME}/lustre/kaiju_${W}_grep_C"
PROC_DIR="${HOME}/lustre/aleix_gff_${W}_process_out"
NEW_TIARA_DIR="${HOME}/lustre/new_tiara_${W}"
FLON_DIR="${HOME}/lustre/flon_${W}"

# Careful: R script expects OUT_FILE as prefix/path like this
OUT_DIR="${HOME}/lustre/tables_filter_${W}"
mkdir -p "$OUT_DIR"

R_LOG="${OUT_DIR}/R_logs_kaiju_process_filters_${W}.log"

echo "R log for kaiju_process_filters - ${W}" > "$R_LOG"

if [[ ! -f "$SAMPLES_FILE" ]]; then
    echo "ERROR: Samples file not found:"
    echo "$SAMPLES_FILE"
    exit 1
fi

TOTAL_SAMPLES="$(grep -cv '^[[:space:]]*$' "$SAMPLES_FILE")"
CURRENT=0

echo
echo "========================================"
echo "Kaiju process filters"
echo "Project: $W"
echo "Samples file: $SAMPLES_FILE"
echo "Total samples: $TOTAL_SAMPLES"
echo "Output dir: $OUT_DIR"
echo "R log: $R_LOG"
echo "========================================"

# Load R module if available.
# If you are already in the correct environment, this will not hurt.
if command -v module >/dev/null 2>&1; then
    echo
    echo "Loading R module..."
    module load cesga/system R/4.2.2
    echo "R module loaded"
else
    echo
    echo "WARNING: 'module' command not found."
    echo "Continuing with current R/Rscript environment."
fi

while read -r SAMPLE; do
    [[ -z "$SAMPLE" ]] && continue

    CURRENT=$(( CURRENT + 1 ))

    echo
    echo "========================================"
    echo "[$CURRENT/$TOTAL_SAMPLES] Sample: $SAMPLE"
    echo "========================================"

    KAIJU_FILE="${KAIJU_DIR}/${SAMPLE}_kaiju_faa_names_grep_C.out"
    PROC_GTF_FILE="${PROC_DIR}/${SAMPLE}_gff_processed.txt"
    NEW_TIARA_FILE="${NEW_TIARA_DIR}/${SAMPLE}_new_tiara.txt"
    FLON_FILE="${FLON_DIR}/${SAMPLE}_filter_lo_names.txt"

    # Careful: keep this as sample path/prefix, not OUT_DIR variable alone
    OUT_FILE="${OUT_DIR}/${SAMPLE}"

    echo "Checking input files..."

    missing=0

    for file in "$KAIJU_FILE" "$PROC_GTF_FILE" "$NEW_TIARA_FILE" "$FLON_FILE"; do
        if [[ ! -f "$file" ]]; then
            echo "ERROR: Missing input file:"
            echo "$file"
            missing=1
        fi
    done

    if [[ "$missing" -eq 1 ]]; then
        echo "Stopping because one or more input files are missing for sample: $SAMPLE"
        exit 1
    fi

    echo "Input files OK"

    echo "Running kaiju_process_FUNCTIONS_ARG_old_pipe.R"
    echo "Output prefix: $OUT_FILE"

    {
        echo
        echo "===== [$CURRENT/$TOTAL_SAMPLES] $SAMPLE ====="
        echo "KAIJU_FILE: $KAIJU_FILE"
        echo "PROC_GTF_FILE: $PROC_GTF_FILE"
        echo "NEW_TIARA_FILE: $NEW_TIARA_FILE"
        echo "FLON_FILE: $FLON_FILE"
        echo "OUT_FILE: $OUT_FILE"

        Rscript "${HOME}/scripts/leuven/Rscripts/kaiju_process_FUNCTIONS_ARG_old_pipe.R" \
            "$KAIJU_FILE" \
            "$PROC_GTF_FILE" \
            "$NEW_TIARA_FILE" \
            "$FLON_FILE" \
            "$OUT_FILE"
    } >> "$R_LOG" 2>&1

    echo "DONE [$CURRENT/$TOTAL_SAMPLES]: $SAMPLE"

done < "$SAMPLES_FILE"

echo
echo "========================================"
echo "All samples finished."
echo "========================================"
echo "Output dir:"
echo "$OUT_DIR"
echo
echo "R output was saved here:"
echo "$R_LOG"
