#!/usr/bin/env bash

# check_faa_vs_processed.sh
# Compare number of sequences in final_faa (*.faa) to rows-1 in processed outputs (*.txt)

# check that GFF3 vs FAA have the same number of genes

W=coass_update

FAA_DIR="lustre/aleix_gff_process_big2_${W}/final_faa"
PROC_DIR="lustre/aleix_gff_${W}_process_out"

ok=0
mismatch=0
missing=0
total=0

# find every *_filter1_genes.faa and derive the sample name
while IFS= read -r -d '' faa; do
  (( total++ ))
  base="$(basename -- "$faa")"
  sample="${base%_filter1_genes.faa}"
  txt="${PROC_DIR}/${sample}_gff_processed.txt"

  # count sequences in FAA (lines starting with '>')
  if [[ -f "$faa" ]]; then
    n_faa=$(grep -c '^>' "$faa" 2>/dev/null || echo 0)
  else
    echo "[MISS] ${sample} -> missing FAA file: $faa"
    (( missing++ ))
    continue
  fi

  # count rows in processed TXT minus 1 for header
  if [[ -f "$txt" ]]; then
    # use command substitution to avoid printing filename
    n_txt_total=$(wc -l < "$txt" 2>/dev/null || echo 0)
    # guard against negative in case of empty file
    if [[ "$n_txt_total" -gt 0 ]]; then
      n_txt=$(( n_txt_total - 1 ))
    else
      n_txt=0
    fi
  else
    echo "[MISS] ${sample} -> missing processed TXT: $txt"
    (( missing++ ))
    continue
  fi

  if [[ "$n_faa" -eq "$n_txt" ]]; then
    echo "[OK]  ${sample} -> FAA: ${n_faa} == TXT(rows-1): ${n_txt}"
    (( ok++ ))
  else
    echo "[BAD] ${sample} -> FAA: ${n_faa} != TXT(rows-1): ${n_txt}"
    (( mismatch++ ))
  fi
done < <(find "$FAA_DIR" -maxdepth 1 -type f -name '*_filter1_genes.faa' -print0 | sort -z)

echo "---- Summary ----"
echo "Total FAA files checked: $total"
echo "OK: $ok"
echo "MISMATCH: $mismatch"
echo "MISSING: $missing"

# exit non-zero if any mismatch or missing
if (( mismatch > 0 || missing > 0 )); then
  exit 1
else
  exit 0
fi
