#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C

W="coass_update"
NAMES_FILE="data/clean/names_${W}.txt"

# input dirs you showed
F1_DIR="lustre/aleix_gff_process_big2_${W}/final_faa"
F3_DIR="lustre/aleix_gff_process_big2_${W}_filter3/final_faa"

# >=50 outputs we generated before
F1_F50_DIR="lustre/genes_${W}_f1_filter50"
F3_F50_DIR="lustre/genes_${W}_f3_filter50"

OUT_DIR="lustre/reports"
OUT_TSV="${OUT_DIR}/genes_${W}_counts_wide.tsv"
mkdir -p "$OUT_DIR"

# counter: use seqkit if available, else grep '^>'
count_seqs() {
  local f="$1"
  [[ -s "$f" ]] || { echo 0; return 0; }
  if command -v seqkit >/dev/null 2>&1; then
    seqkit stats -Ta "$f" 2>/dev/null | awk 'NR==2{print $4+0}'
  else
    awk '/^>/{c++} END{print c+0}' "$f"
  fi
}

[[ -s "$NAMES_FILE" ]] || { echo "[ERROR] Missing or empty $NAMES_FILE"; exit 1; }
mapfile -t SAMPLES < <(grep -v '^\s*#' "$NAMES_FILE" | sed '/^\s*$/d')

# header
echo -e "Sample\tf1_orig\tf1_ge50aa\tf3_orig\tf3_ge50aa" > "$OUT_TSV"

for S in "${SAMPLES[@]}"; do
  f1="${F1_DIR}/${S}_filter1_genes.faa"
  f3="${F3_DIR}/${S}_filter3_genes.faa"
  f1f="${F1_F50_DIR}/${S}_filter1_genes_filter50.faa"
  f3f="${F3_F50_DIR}/${S}_filter3_genes_filter50.faa"

  n1=$(count_seqs "$f1")
  n1f=$(count_seqs "$f1f")
  n3=$(count_seqs "$f3")
  n3f=$(count_seqs "$f3f")

  echo -e "${S}\t${n1}\t${n1f}\t${n3}\t${n3f}" >> "$OUT_TSV"
done

echo "[OK] Wrote: $OUT_TSV"
echo "view: column -t ${OUT_TSV}"
