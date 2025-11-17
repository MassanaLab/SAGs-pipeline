#!/usr/bin/env bash
# 3X.8-excluded.sh
#
# For each sample folder in store/final_genomes_${W}:
#   - Take SAMPLE_filter1_scaffolds.fasta (f1)
#   - Take SAMPLE_filter3_scaffolds.fasta (f3)
#   - Find contigs present in f1 but not in f3
#   - Write them to SAMPLE_excluded.fasta

#set -euo pipefail
export LC_ALL=C
shopt -s nullglob

module load seqkit

W="${W:-coass_update}"
BASE="store/final_genomes_${W}_test"

made=0       # excluded FASTAs with sequences
empty=0      # excluded FASTAs that are empty
missing=0    # samples missing f1 or f3

echo "Base directory: $BASE"
echo

for d in "$BASE"/*/; do
  sample="$(basename "$d")"
  f1="${d}/${sample}_filter1_scaffolds.fasta"
  f3="${d}/${sample}_filter3_scaffolds.fasta"
  out="${d}/${sample}_excluded.fasta"

  if [[ ! -f "$f1" || ! -f "$f3" ]]; then
    echo "WARN: $sample -> missing filter1 or filter3 scaffolds"
    ((missing++))
    continue
  fi

  # Temporary ID lists
  ids_f1="${d}/.f1.ids"
  ids_f3="${d}/.f3.ids"
  ids_excl="${d}/.excluded.ids"

  # Get unique IDs (sequence names)
  seqkit fx2tab -n "$f1" | awk '{print $1}' | sort -u > "$ids_f1"
  seqkit fx2tab -n "$f3" | awk '{print $1}' | sort -u > "$ids_f3"

  # IDs present in f1 but not in f3
  comm -23 "$ids_f1" "$ids_f3" > "$ids_excl"

  if [[ -s "$ids_excl" ]]; then
    seqkit grep -n -f "$ids_excl" "$f1" > "$out"
    n_ids=$(wc -l < "$ids_excl")
    echo "EXCLUDED: $sample -> $n_ids IDs -> $(basename "$out")"
    ((made++))
  else
    : > "$out"
    echo "NONE: $sample -> no excluded contigs (created empty $(basename "$out"))"
    ((empty++))
  fi

  # Clean up
  rm -f "$ids_f1" "$ids_f3" "$ids_excl"
done

echo
echo "✅ Done."
echo "  Excluded FASTAs with sequences: $made"
echo "  Excluded FASTAs empty:          $empty"
echo "  Samples missing f1/f3:          $missing"
