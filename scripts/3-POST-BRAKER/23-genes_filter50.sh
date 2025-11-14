#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C

W="coass_update"
NAMES_FILE="data/clean/names_${W}.txt"

# Source dirs (as you showed)
F1_DIR="lustre/aleix_gff_process_big2_${W}/final_faa"
F3_DIR="lustre/aleix_gff_process_big2_${W}_filter3/final_faa"

# Output dirs
OUT_F1="lustre/genes_${W}_f1_filter50"
OUT_F3="lustre/genes_${W}_f3_filter50"

MINAA=50

# Ensure seqkit
if ! command -v seqkit >/dev/null 2>&1; then
  module load seqkit/2.1.0 2>/dev/null || true
fi
command -v seqkit >/dev/null 2>&1 || { echo "[ERROR] seqkit not found"; exit 1; }

[[ -s "$NAMES_FILE" ]] || { echo "[ERROR] Missing or empty $NAMES_FILE"; exit 1; }
mkdir -p "$OUT_F1" "$OUT_F3"

# Read samples (ignore blanks/comments)
mapfile -t SAMPLES < <(grep -v '^\s*#' "$NAMES_FILE" | sed '/^\s*$/d')

TOTAL="${#SAMPLES[@]}"
i=0

for SAMPLE in "${SAMPLES[@]}"; do
  i=$((i+1))
  printf '[FILTER50] %2d/%-2d %s\n' "$i" "$TOTAL" "$SAMPLE"

  f1="${F1_DIR}/${SAMPLE}_filter1_genes.faa"
  f3="${F3_DIR}/${SAMPLE}_filter3_genes.faa"

  out1="${OUT_F1}/${SAMPLE}_filter1_genes_filter50.faa"
  out3="${OUT_F3}/${SAMPLE}_filter3_genes_filter50.faa"

  # --- Filter1 ---
  if [[ -s "$f1" ]]; then
    total1=$(seqkit stats -Ta "$f1" 2>/dev/null | awk 'NR==2{print $4+0}')
    seqkit seq -m "$MINAA" "$f1" > "$out1"
    kept1=$(seqkit stats -Ta "$out1" 2>/dev/null | awk 'NR==2{print $4+0}')
    lt50_1=$(( total1 - kept1 ))
    pct_lt1=$(awk -v a="$lt50_1" -v t="$total1" 'BEGIN{ if(t>0) printf "%.2f", (a*100)/t; else print "0.00" }')
    printf '  [F1] kept %d / %d  (lt50=%d, %s%%) -> %s\n' "$kept1" "$total1" "$lt50_1" "$pct_lt1" "$out1"
  else
    echo "  [F1] WARN: missing or empty $f1" >&2
  fi

  # --- Filter3 ---
  if [[ -s "$f3" ]]; then
    total3=$(seqkit stats -Ta "$f3" 2>/dev/null | awk 'NR==2{print $4+0}')
    seqkit seq -m "$MINAA" "$f3" > "$out3"
    kept3=$(seqkit stats -Ta "$out3" 2>/dev/null | awk 'NR==2{print $4+0}')
    lt50_3=$(( total3 - kept3 ))
    pct_lt3=$(awk -v a="$lt50_3" -v t="$total3" 'BEGIN{ if(t>0) printf "%.2f", (a*100)/t; else print "0.00" }')
    printf '  [F3] kept %d / %d  (lt50=%d, %s%%) -> %s\n' "$kept3" "$total3" "$lt50_3" "$pct_lt3" "$out3"
  else
    echo "  [F3] WARN: missing or empty $f3" >&2
  fi
done

echo "[DONE] Outputs:"
echo "  - ${OUT_F1}/<SAMPLE}_filter1_genes_filter50.faa"
echo "  - ${OUT_F3}/<SAMPLE}_filter3_genes_filter50.faa"
