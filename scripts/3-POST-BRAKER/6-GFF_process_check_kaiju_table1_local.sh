#!/usr/bin/env bash

set -euo pipefail

W="${1:-coass_guigo}"
SAMPLES_FILE="data/clean/names_${W}.txt"

GFF_DIR="${HOME}/lustre/aleix_gff_process_big2_${W}/final_gff3"
FAA_DIR="${HOME}/lustre/aleix_gff_process_big2_${W}/final_faa"
EMAPP_DIR="${HOME}/lustre/eggnog_${W}_clean_skip4"
TIARA_DIR="${HOME}/lustre/qbt_${W}_filter1000_ess/tiara"
PROC_DIR="${HOME}/lustre/aleix_gff_${W}_process_out"
TABLE1_DIR="${HOME}/lustre/tables1_${W}"
KAIJU_DIR="${HOME}/lustre/kaiju_${W}_grep_C"

mkdir -p "$PROC_DIR" "$TABLE1_DIR"

CHECK_REPORT="${TABLE1_DIR}/check_faa_vs_processed_${W}.tsv"
R_LOG="${TABLE1_DIR}/R_logs_${W}.log"

echo -e "sample\tfaa_genes\tprocessed_genes\tstatus" > "$CHECK_REPORT"
echo "R log for ${W}" > "$R_LOG"

TOTAL_SAMPLES="$(grep -cv '^[[:space:]]*$' "$SAMPLES_FILE")"
CURRENT=0

echo
echo "========================================"
echo "Project: $W"
echo "Samples: $TOTAL_SAMPLES"
echo "Check report: $CHECK_REPORT"
echo "R log: $R_LOG"
echo "========================================"

while read -r SAMPLE; do
    [[ -z "$SAMPLE" ]] && continue

    CURRENT=$(( CURRENT + 1 ))

    echo
    echo "========================================"
    echo "[$CURRENT/$TOTAL_SAMPLES] Sample: $SAMPLE"
    echo "========================================"

    GFF_FILE="${GFF_DIR}/${SAMPLE}_filter1.gff3"
    FAA_FILE="${FAA_DIR}/${SAMPLE}_filter1_genes.faa"
    EMAPPER_FILE="${EMAPP_DIR}/${SAMPLE}_eggnog.emapper.annotations_clean"
    TIARA_FILE="${TIARA_DIR}/${SAMPLE}"
    PROC_FILE="${PROC_DIR}/${SAMPLE}_gff_processed.txt"
    KAIJU_FILE="${KAIJU_DIR}/${SAMPLE}_kaiju_faa_names_grep_C.out"
    TABLE1_FILE="${TABLE1_DIR}/${SAMPLE}_table1.tsv"

    echo "Checking input files..."

    for file in "$GFF_FILE" "$FAA_FILE" "$EMAPPER_FILE" "$TIARA_FILE" "$KAIJU_FILE"; do
        if [[ ! -f "$file" ]]; then
            echo "ERROR: Missing required input file:"
            echo "$file"
            exit 1
        fi
    done

    echo "Input files OK"

    echo "Step 1/3: Processing GFF"

    {
        echo
        echo "===== [$CURRENT/$TOTAL_SAMPLES] $SAMPLE - ALEIX_get_prediction_stats_v2.R ====="
        Rscript "${HOME}/scripts/full_remake/ALEIX_get_prediction_stats_v2.R" \
            "$GFF_FILE" \
            "$EMAPPER_FILE" \
            "$TIARA_FILE" \
            "$PROC_FILE"
    } >> "$R_LOG" 2>&1

    if [[ ! -f "$PROC_FILE" ]]; then
        echo "ERROR: Processed GFF file was not created:"
        echo "$PROC_FILE"
        echo "Check R log:"
        echo "$R_LOG"
        exit 1
    fi

    echo "Processed GFF created"

    echo "Step 2/3: Checking FAA vs processed TXT"

    n_faa="$(grep -c '^>' "$FAA_FILE" || echo 0)"
    n_txt_total="$(wc -l < "$PROC_FILE" || echo 0)"

    if [[ "$n_txt_total" -gt 0 ]]; then
        n_txt=$(( n_txt_total - 1 ))
    else
        n_txt=0
    fi

    echo "FAA genes:       $n_faa"
    echo "Processed genes: $n_txt"

    if [[ "$n_faa" -eq "$n_txt" ]]; then
        status="OK"
        echo "Check OK"
    else
        status="BAD"
        echo "ERROR: Count mismatch for $SAMPLE"
        echo "FAA: $n_faa != processed TXT rows-1: $n_txt"
    fi

    echo -e "${SAMPLE}\t${n_faa}\t${n_txt}\t${status}" >> "$CHECK_REPORT"

    if [[ "$status" == "BAD" ]]; then
        echo "Stopping because this sample failed the count check."
        echo "Check report:"
        echo "$CHECK_REPORT"
        exit 1
    fi

    echo "Step 3/3: Making table1"

    {
        echo
        echo "===== [$CURRENT/$TOTAL_SAMPLES] $SAMPLE - kaiju_process_TABLE1_FUNCTIONS_ARG.R ====="
        Rscript "${HOME}/scripts/leuven/Rscripts/kaiju_process_TABLE1_FUNCTIONS_ARG.R" \
            "$KAIJU_FILE" \
            "$PROC_FILE" \
            "$TABLE1_FILE"
    } >> "$R_LOG" 2>&1

    if [[ ! -f "$TABLE1_FILE" ]]; then
        echo "ERROR: Table1 file was not created:"
        echo "$TABLE1_FILE"
        echo "Check R log:"
        echo "$R_LOG"
        exit 1
    fi

    echo "Table1 created"
    echo "DONE [$CURRENT/$TOTAL_SAMPLES]: $SAMPLE"

done < "$SAMPLES_FILE"


echo
echo "========================================"
echo "Final FAA vs processed TXT check summary"
echo "========================================"

column -t "$CHECK_REPORT"

n_bad="$(awk 'NR > 1 && $4 != "OK" {count++} END {print count+0}' "$CHECK_REPORT")"
n_ok="$(awk 'NR > 1 && $4 == "OK" {count++} END {print count+0}' "$CHECK_REPORT")"
n_total="$(awk 'NR > 1 {count++} END {print count+0}' "$CHECK_REPORT")"

echo
echo "Total checked: $n_total"
echo "OK:            $n_ok"
echo "BAD:           $n_bad"

if [[ "$n_bad" -eq 0 ]]; then
    echo
    echo "All samples have matching FAA and processed TXT gene counts."
    echo "Check report:"
    echo "$CHECK_REPORT"
    echo
    echo "R output was saved here:"
    echo "$R_LOG"
else
    echo
    echo "Some samples have mismatching counts. Check:"
    echo "$CHECK_REPORT"
    exit 1
fi

echo
echo "All samples finished."
