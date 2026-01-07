#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C
shopt -s nullglob

###############################################################################
# CONFIG (your keyword)
###############################################################################
W="coass_ICM0002"
NAMES_FILE="data/clean/names_${W}.txt"

# Raw gene FASTA locations (same ones as the length-filter script input)
F1_DIR="lustre/aleix_gff_process_big2_${W}/final_faa"
F3_DIR="lustre/aleix_gff_process_big2_${W}_filter3/final_faa"

# Where the filtered FASTAs were written by the length-filter script
#   lustre/genes_${W}_f{1,3}_filter{50,100,200}/*_filter{1,3}_genes_filter{50,100,200}.faa
F1_FILTERED_DIR_50="lustre/genes_${W}_f1_filter50"
F3_FILTERED_DIR_50="lustre/genes_${W}_f3_filter50"

F1_FILTERED_DIR_100="lustre/genes_${W}_f1_filter100"
F3_FILTERED_DIR_100="lustre/genes_${W}_f3_filter100"

F1_FILTERED_DIR_200="lustre/genes_${W}_f1_filter200"
F3_FILTERED_DIR_200="lustre/genes_${W}_f3_filter200"

# Output
OUT_DIR="lustre/gene_counts_${W}"
OUT="${OUT_DIR}/gene_counts_50_100_200_complete.tsv"
OUT_PRETTY="${OUT_DIR}/gene_counts_50_100_200_complete_pretty.tsv"

mkdir -p "${OUT_DIR}"

###############################################################################
# HELPERS
###############################################################################
count_headers() {
  local f="$1"
  [[ -s "$f" ]] && (grep -c '^>' "$f" 2>/dev/null || echo 0) || echo 0
}
pct() {
  awk -v a="$1" -v t="$2" 'BEGIN{ if(t>0) printf "%.2f", (a*100)/t; else printf "0.00" }'
}

###############################################################################
# INPUT CHECKS + SAMPLE LIST
###############################################################################
[[ -s "$NAMES_FILE" ]] || { echo "[ERROR] Missing or empty $NAMES_FILE"; exit 1; }

mapfile -t SAMPLES < <(grep -v '^\s*#' "$NAMES_FILE" | sed '/^\s*$/d')
TOTAL="${#SAMPLES[@]}"
(( TOTAL > 0 )) || { echo "[ERROR] No samples found in $NAMES_FILE"; exit 1; }

###############################################################################
# HEADER
###############################################################################
echo -e "Sample\t\
f1_total\tf1_ge50aa\tf1_lt50aa\tf1_%lt50\t\
f1_ge100aa\tf1_lt100aa\tf1_%lt100\t\
f1_ge200aa\tf1_lt200aa\tf1_%lt200\t\
f3_total\tf3_ge50aa\tf3_lt50aa\tf3_%lt50\t\
f3_ge100aa\tf3_lt100aa\tf3_%lt100\t\
f3_ge200aa\tf3_lt200aa\tf3_%lt200" > "$OUT"

###############################################################################
# LOOP
###############################################################################
i=0
for SAMPLE in "${SAMPLES[@]}"; do
  i=$((i+1))
  printf '[GENECOUNT] %4d/%-4d (%3d%%) %s\n' "$i" "$TOTAL" $((i*100/TOTAL)) "$SAMPLE"

  # raw gene FASTAs
  f1="${F1_DIR}/${SAMPLE}_filter1_genes.faa"
  f3="${F3_DIR}/${SAMPLE}_filter3_genes.faa"

  # filtered FASTAs (>=50, >=100, >=200)
  f1_50="${F1_FILTERED_DIR_50}/${SAMPLE}_filter1_genes_filter50.faa"
  f3_50="${F3_FILTERED_DIR_50}/${SAMPLE}_filter3_genes_filter50.faa"

  f1_100="${F1_FILTERED_DIR_100}/${SAMPLE}_filter1_genes_filter100.faa"
  f3_100="${F3_FILTERED_DIR_100}/${SAMPLE}_filter3_genes_filter100.faa"

  f1_200="${F1_FILTERED_DIR_200}/${SAMPLE}_filter1_genes_filter200.faa"
  f3_200="${F3_FILTERED_DIR_200}/${SAMPLE}_filter3_genes_filter200.faa"

  # totals (raw)
  f1_total=$(count_headers "$f1")
  f3_total=$(count_headers "$f3")

  # >=50
  f1_ge50=$(count_headers "$f1_50")
  f3_ge50=$(count_headers "$f3_50")

  f1_lt50=$(( f1_total - f1_ge50 )); (( f1_lt50 < 0 )) && f1_lt50=0
  f3_lt50=$(( f3_total - f3_ge50 )); (( f3_lt50 < 0 )) && f3_lt50=0

  f1_pct_lt50=$(pct "$f1_lt50" "$f1_total")
  f3_pct_lt50=$(pct "$f3_lt50" "$f3_total")

  # >=100
  f1_ge100=$(count_headers "$f1_100")
  f3_ge100=$(count_headers "$f3_100")

  f1_lt100=$(( f1_total - f1_ge100 )); (( f1_lt100 < 0 )) && f1_lt100=0
  f3_lt100=$(( f3_total - f3_ge100 )); (( f3_lt100 < 0 )) && f3_lt100=0

  f1_pct_lt100=$(pct "$f1_lt100" "$f1_total")
  f3_pct_lt100=$(pct "$f3_lt100" "$f3_total")

  # >=200
  f1_ge200=$(count_headers "$f1_200")
  f3_ge200=$(count_headers "$f3_200")

  f1_lt200=$(( f1_total - f1_ge200 )); (( f1_lt200 < 0 )) && f1_lt200=0
  f3_lt200=$(( f3_total - f3_ge200 )); (( f3_lt200 < 0 )) && f3_lt200=0

  f1_pct_lt200=$(pct "$f1_lt200" "$f1_total")
  f3_pct_lt200=$(pct "$f3_lt200" "$f3_total")

  # warn if expected files missing
  [[ -s "$f1" ]] || echo "  [WARN] Missing raw F1 : $f1" >&2
  [[ -s "$f3" ]] || echo "  [WARN] Missing raw F3 : $f3" >&2

  [[ -s "$f1_50"  ]] || echo "  [WARN] Missing filtered F1 >=50aa : $f1_50"  >&2
  [[ -s "$f3_50"  ]] || echo "  [WARN] Missing filtered F3 >=50aa : $f3_50"  >&2
  [[ -s "$f1_100" ]] || echo "  [WARN] Missing filtered F1 >=100aa: $f1_100" >&2
  [[ -s "$f3_100" ]] || echo "  [WARN] Missing filtered F3 >=100aa: $f3_100" >&2
  [[ -s "$f1_200" ]] || echo "  [WARN] Missing filtered F1 >=200aa: $f1_200" >&2
  [[ -s "$f3_200" ]] || echo "  [WARN] Missing filtered F3 >=200aa: $f3_200" >&2

  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$SAMPLE" \
    "$f1_total" "$f1_ge50" "$f1_lt50" "$f1_pct_lt50" \
    "$f1_ge100" "$f1_lt100" "$f1_pct_lt100" \
    "$f1_ge200" "$f1_lt200" "$f1_pct_lt200" \
    "$f3_total" "$f3_ge50" "$f3_lt50" "$f3_pct_lt50" \
    "$f3_ge100" "$f3_lt100" "$f3_pct_lt100" \
    "$f3_ge200" "$f3_lt200" "$f3_pct_lt200" \
    >> "$OUT"
done

echo "[DONE] Wrote $OUT"
column -t -s $'\t' "$OUT" > "$OUT_PRETTY"
echo "[DONE] Wrote $OUT_PRETTY"
