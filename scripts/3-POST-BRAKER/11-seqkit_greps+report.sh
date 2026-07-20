#!/usr/bin/env bash

set -euo pipefail

# Usage:
#   bash scripts/coass_guigo/25-seqkit_filters_and_report.sh coass_guigo
#
# If no argument is given, use coass_guigo

W="${1:-coass_guigo}"

NAMES_FILE="data/clean/names_${W}.txt"

TK_DIR="${HOME}/lustre/tokeep_${W}"
FC_DIR="${HOME}/lustre/filters_clean_${W}"
TABLES_DIR="${HOME}/lustre/tables_filter_${W}"
SC_DIR="${HOME}/lustre/aleix_gff_process_big2_${W}/assemblies1_clean"

REPORT_TSV="${FC_DIR}/filter_counts_report.tsv"
REPORT_PRETTY="${FC_DIR}/filter_counts_report_pretty.txt"

echo
echo "========================================"
echo "Seqkit filters + filter count report"
echo "Project: $W"
echo "Names file: $NAMES_FILE"
echo "========================================"

if [[ ! -f "$NAMES_FILE" ]]; then
    echo "ERROR: names file not found:"
    echo "$NAMES_FILE"
    exit 1
fi

if command -v module >/dev/null 2>&1; then
    echo
    echo "Loading seqkit module..."
    module load seqkit
    echo "seqkit module loaded"
else
    echo
    echo "WARNING: module command not found."
    echo "Continuing assuming seqkit is already available."
fi

if ! command -v seqkit >/dev/null 2>&1; then
    echo "ERROR: seqkit command not found."
    echo "Load seqkit manually or check your environment."
    exit 1
fi

TOTAL="$(grep -cv '^[[:space:]]*$' "$NAMES_FILE")"

echo
echo "Total samples: $TOTAL"
echo "Input assemblies: $SC_DIR"
echo "Input tables:     $TABLES_DIR"
echo "Tokeep dir:       $TK_DIR"
echo "Output FASTAs:    $FC_DIR"

echo
echo "Resetting output folders..."

rm -rf "$TK_DIR"
rm -rf "$FC_DIR"

mkdir -p "$TK_DIR"
mkdir -p "${FC_DIR}/filter1"
mkdir -p "${FC_DIR}/filter2"
mkdir -p "${FC_DIR}/filter3"

echo "Output folders ready"


# -------------------------
# Step 1: create filtered FASTAs
# -------------------------

echo
echo "========================================"
echo "Step 1/2: Creating filtered FASTAs"
echo "========================================"

i=0

while IFS= read -r SAMPLE; do
    [[ -z "$SAMPLE" ]] && continue

    i=$(( i + 1 ))

    echo
    echo "[$i/$TOTAL] Processing sample: $SAMPLE"

    ASM_FILE="${SC_DIR}/${SAMPLE}.fasta"

    TABLE_F1="${TABLES_DIR}/${SAMPLE}_table6_filter1.tsv"
    TABLE_F2="${TABLES_DIR}/${SAMPLE}_table6_filter2.tsv"
    TABLE_F3="${TABLES_DIR}/${SAMPLE}_table6_filter3.tsv"

    KEEP_F1="${TK_DIR}/${SAMPLE}_filter1_tokeep.txt"
    KEEP_F2="${TK_DIR}/${SAMPLE}_filter2_tokeep.txt"
    KEEP_F3="${TK_DIR}/${SAMPLE}_filter3_tokeep.txt"

    OUT_F1="${FC_DIR}/filter1/${SAMPLE}_filter1_clean.fasta"
    OUT_F2="${FC_DIR}/filter2/${SAMPLE}_filter2_clean.fasta"
    OUT_F3="${FC_DIR}/filter3/${SAMPLE}_filter3_clean.fasta"

    echo "Checking input files..."

    for file in "$ASM_FILE" "$TABLE_F1" "$TABLE_F2" "$TABLE_F3"; do
        if [[ ! -f "$file" ]]; then
            echo "ERROR: Missing input file:"
            echo "$file"
            exit 1
        fi
    done

    echo "Creating tokeep lists..."

    awk '{print $1}' "$TABLE_F1" | tail -n +2 > "$KEEP_F1"
    awk '{print $1}' "$TABLE_F2" | tail -n +2 > "$KEEP_F2"
    awk '{print $1}' "$TABLE_F3" | tail -n +2 > "$KEEP_F3"

    n_keep_f1="$(wc -l < "$KEEP_F1")"
    n_keep_f2="$(wc -l < "$KEEP_F2")"
    n_keep_f3="$(wc -l < "$KEEP_F3")"

    echo "Tokeep filter1: $n_keep_f1"
    echo "Tokeep filter2: $n_keep_f2"
    echo "Tokeep filter3: $n_keep_f3"

    echo "Running seqkit grep..."

    seqkit grep -f "$KEEP_F1" "$ASM_FILE" > "$OUT_F1"
    seqkit grep -f "$KEEP_F2" "$ASM_FILE" > "$OUT_F2"
    seqkit grep -f "$KEEP_F3" "$ASM_FILE" > "$OUT_F3"

    c1="$(grep -c '^>' "$OUT_F1" || echo 0)"
    c2="$(grep -c '^>' "$OUT_F2" || echo 0)"
    c3="$(grep -c '^>' "$OUT_F3" || echo 0)"

    echo "Created filter1 FASTA: $c1 contigs"
    echo "Created filter2 FASTA: $c2 contigs"
    echo "Created filter3 FASTA: $c3 contigs"

    echo "DONE [$i/$TOTAL]: $SAMPLE"

done < "$NAMES_FILE"


# -------------------------
# Step 2: make count report
# -------------------------

echo
echo "========================================"
echo "Step 2/2: Creating filter count report"
echo "========================================"

max_name_len="$(awk '{print length}' "$NAMES_FILE" | sort -nr | head -1)"
(( max_name_len < 28 )) && max_name_len=28

echo -e "Sample\tfilter1\tfilter2\tfilter3\tdelta12\tdelta23\tmonotonic" > "$REPORT_TSV"

{
    printf "%-*s  %10s  %10s  %10s  %8s  %8s  %s\n" \
        "$max_name_len" "Sample" "filter1" "filter2" "filter3" "delta12" "delta23" "monotonic"

    printf "%-*s  %10s  %10s  %10s  %8s  %8s  %s\n" \
        "$max_name_len" "$(printf -- '%.0s-' $(seq 1 "$max_name_len"))" \
        "----------" "----------" "----------" "--------" "--------" "---------"
} > "$REPORT_PRETTY"

violations=0
i=0

while IFS= read -r SAMPLE; do
    [[ -z "$SAMPLE" ]] && continue

    i=$(( i + 1 ))

    f1="${FC_DIR}/filter1/${SAMPLE}_filter1_clean.fasta"
    f2="${FC_DIR}/filter2/${SAMPLE}_filter2_clean.fasta"
    f3="${FC_DIR}/filter3/${SAMPLE}_filter3_clean.fasta"

    c1=0
    c2=0
    c3=0

    [[ -s "$f1" ]] && c1="$(grep -c '^>' "$f1" || echo 0)"
    [[ -s "$f2" ]] && c2="$(grep -c '^>' "$f2" || echo 0)"
    [[ -s "$f3" ]] && c3="$(grep -c '^>' "$f3" || echo 0)"

    d12=$(( c1 - c2 ))
    d23=$(( c2 - c3 ))

    if [[ "$c1" -ge "$c2" && "$c2" -ge "$c3" ]]; then
        mono_txt="OK"
    else
        mono_txt="WARN"
        violations=$(( violations + 1 ))
    fi

    printf "%s\t%d\t%d\t%d\t%d\t%d\t%s\n" \
        "$SAMPLE" "$c1" "$c2" "$c3" "$d12" "$d23" "$mono_txt" >> "$REPORT_TSV"

    printf "%-*s  %10d  %10d  %10d  %8d  %8d  %s\n" \
        "$max_name_len" "$SAMPLE" "$c1" "$c2" "$c3" "$d12" "$d23" "$mono_txt" >> "$REPORT_PRETTY"

done < "$NAMES_FILE"


echo
echo "========================================"
echo "Final filter count summary"
echo "========================================"

cat "$REPORT_PRETTY"

echo
echo "TSV report:"
echo "$REPORT_TSV"

echo
echo "Pretty report:"
echo "$REPORT_PRETTY"

if (( violations > 0 )); then
    echo
    echo "WARNING: Monotonicity violations found: $violations"
    echo "Expected: filter1 >= filter2 >= filter3"
    exit 1
else
    echo
    echo "All samples are monotonic: filter1 >= filter2 >= filter3"
fi

echo
echo "All done."
