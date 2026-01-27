#!/usr/bin/env bash

W="coass_update"
NAMES_FILE="data/clean/names_${W}.txt"
FC_DIR="lustre/filters_clean_${W}"

REPORT_TSV="${FC_DIR}/filter_counts_report.tsv"
REPORT_PRETTY="${FC_DIR}/filter_counts_report_pretty.txt"

[[ -f "$NAMES_FILE" ]] || { echo "ERROR: names file not found: $NAMES_FILE" >&2; exit 1; }
mkdir -p "${FC_DIR}"

# Compute max sample name length for clean alignment
max_name_len=$(awk '{print length}' "$NAMES_FILE" | sort -nr | head -1)
# Minimum width to avoid cramping
(( max_name_len < 28 )) && max_name_len=28

# Headers
echo -e "Sample\tfilter1\tfilter2\tfilter3\tdelta12\tdelta23\tmonotonic" > "$REPORT_TSV"

# Pretty header
{
  printf "%-*s  %10s  %10s  %10s  %8s  %8s  %s\n" \
    "$max_name_len" "Sample" "filter1" "filter2" "filter3" "delta12" "delta23" "monotonic"
  printf "%-*s  %10s  %10s  %10s  %8s  %8s  %s\n" \
    "$max_name_len" "$(printf -- '%.0s-' $(seq 1 $max_name_len))" \
    "----------" "----------" "----------" "--------" "--------" "---------"
} > "$REPORT_PRETTY"

violations=0
while IFS= read -r SAMPLE; do
  f1="${FC_DIR}/filter1/${SAMPLE}_filter1_clean.fasta"
  f2="${FC_DIR}/filter2/${SAMPLE}_filter2_clean.fasta"
  f3="${FC_DIR}/filter3/${SAMPLE}_filter3_clean.fasta"

  c1=0; c2=0; c3=0
  [[ -s "$f1" ]] && c1=$(grep -c '^>' "$f1" || echo 0)
  [[ -s "$f2" ]] && c2=$(grep -c '^>' "$f2" || echo 0)
  [[ -s "$f3" ]] && c3=$(grep -c '^>' "$f3" || echo 0)

  d12=$(( c1 - c2 ))
  d23=$(( c2 - c3 ))

  if [[ $c1 -ge $c2 && $c2 -ge $c3 ]]; then
    mono_txt="OK"
    mono_emoji="✅ OK"
  else
    mono_txt="WARN"
    mono_emoji="❌ WARN"
    ((violations++))
  fi

  # TSV (with emoji in last column; remove emoji if you prefer pure ASCII)
  printf "%s\t%d\t%d\t%d\t%d\t%d\t%s\n" \
    "$SAMPLE" "$c1" "$c2" "$c3" "$d12" "$d23" "$mono_emoji" >> "$REPORT_TSV"

  # Pretty aligned
  printf "%-*s  %10d  %10d  %10d  %8d  %8d  %s\n" \
    "$max_name_len" "$SAMPLE" "$c1" "$c2" "$c3" "$d12" "$d23" "$mono_emoji" >> "$REPORT_PRETTY"

done < "$NAMES_FILE"

echo "TSV   : $REPORT_TSV"
echo "Pretty: $REPORT_PRETTY"
if (( violations > 0 )); then
  echo "Monotonicity violations: $violations (see ❌ rows)."
else
  echo "All samples monotonic: filter1 ≥ filter2 ≥ filter3 ✅"
fi
