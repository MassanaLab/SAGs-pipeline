#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C
shopt -s nullglob

###############################################################################
# CONFIG
###############################################################################
W="coass_ICM0002"
NAMES_FILE="data/clean/names_${W}.txt"

# Source dirs (your correct ones)
F1_DIR="lustre/aleix_gff_process_big2_${W}/final_faa"
F3_DIR="lustre/aleix_gff_process_big2_${W}_filter3/final_faa"

# Length thresholds to apply
LENGTHS=(50 100 200)

# Output base (we’ll create per-threshold dirs under this)
OUT_BASE="lustre"

###############################################################################
# REQUIREMENTS
###############################################################################
# Ensure seqkit is available
if ! command -v seqkit >/dev/null 2>&1; then
  module load seqkit/2.1.0 2>/dev/null || true
fi
command -v seqkit >/dev/null 2>&1 || { echo "[ERROR] seqkit not found"; exit 1; }

[[ -s "$NAMES_FILE" ]] || { echo "[ERROR] Missing or empty $NAMES_FILE"; exit 1; }

# Read samples (ignore blanks/comments)
mapfile -t SAMPLES < <(grep -v '^\s*#' "$NAMES_FILE" | sed '/^\s*$/d')
TOTAL="${#SAMPLES[@]}"
(( TOTAL > 0 )) || { echo "[ERROR] No samples found in $NAMES_FILE"; exit 1; }

# Create all output dirs for all thresholds
for L in "${LENGTHS[@]}"; do
  mkdir -p "${OUT_BASE}/genes_${W}_f1_filter${L}" "${OUT_BASE}/genes_${W}_f3_filter${L}"
done

###############################################################################
# RUN
###############################################################################
i=0
for SAMPLE in "${SAMPLES[@]}"; do
  i=$((i+1))
  printf '[FILTER] %3d/%-3d %s\n' "$i" "$TOTAL" "$SAMPLE"

  f1="${F1_DIR}/${SAMPLE}_filter1_genes.faa"
  f3="${F3_DIR}/${SAMPLE}_filter3_genes.faa"

  # Source checks
  if [[ ! -s "$f1" ]]; then
    echo "  [F1] WARN: missing or empty $f1" >&2
  fi
  if [[ ! -s "$f3" ]]; then
    echo "  [F3] WARN: missing or empty $f3" >&2
  fi

  # Precompute totals once (if present)
  total1=0
  total3=0
  if [[ -s "$f1" ]]; then
    total1=$(seqkit stats -Ta "$f1" 2>/dev/null | awk 'NR==2{print $4+0}')
  fi
  if [[ -s "$f3" ]]; then
    total3=$(seqkit stats -Ta "$f3" 2>/dev/null | awk 'NR==2{print $4+0}')
  fi

  # Apply all thresholds
  for L in "${LENGTHS[@]}"; do
    out1="${OUT_BASE}/genes_${W}_f1_filter${L}/${SAMPLE}_filter1_genes_filter${L}.faa"
    out3="${OUT_BASE}/genes_${W}_f3_filter${L}/${SAMPLE}_filter3_genes_filter${L}.faa"

    # --- F1 ---
    if [[ -s "$f1" ]]; then
      seqkit seq -m "$L" "$f1" > "$out1"
      kept1=$(seqkit stats -Ta "$out1" 2>/dev/null | awk 'NR==2{print $4+0}')
      ltL_1=$(( total1 - kept1 ))
      pct_lt1=$(awk -v a="$ltL_1" -v t="$total1" 'BEGIN{ if(t>0) printf "%.2f", (a*100)/t; else print "0.00" }')
      printf '  [F1 L=%-3d] kept %6d / %6d  (lt%3d=%6d, %6s%%) -> %s\n' \
        "$L" "$kept1" "$total1" "$L" "$ltL_1" "$pct_lt1" "$out1"
    fi

    # --- F3 ---
    if [[ -s "$f3" ]]; then
      seqkit seq -m "$L" "$f3" > "$out3"
      kept3=$(seqkit stats -Ta "$out3" 2>/dev/null | awk 'NR==2{print $4+0}')
      ltL_3=$(( total3 - kept3 ))
      pct_lt3=$(awk -v a="$ltL_3" -v t="$total3" 'BEGIN{ if(t>0) printf "%.2f", (a*100)/t; else print "0.00" }')
      printf '  [F3 L=%-3d] kept %6d / %6d  (lt%3d=%6d, %6s%%) -> %s\n' \
        "$L" "$kept3" "$total3" "$L" "$ltL_3" "$pct_lt3" "$out3"
    fi
  done
done

echo "[DONE] Outputs (per threshold):"
for L in "${LENGTHS[@]}"; do
  echo "  - ${OUT_BASE}/genes_${W}_f1_filter${L}/<SAMPLE>_filter1_genes_filter${L}.faa"
  echo "  - ${OUT_BASE}/genes_${W}_f3_filter${L}/<SAMPLE>_filter3_genes_filter${L}.faa"
done
