#!/usr/bin/env bash
# 3X.1.2-filter3_initial.sh
#
# For each SAMPLE, copy into:
#   store/final_genomes_${W}/${SAMPLE}/
#     SAMPLE_filter3_scaffolds.fasta
#     SAMPLE_filter3.gff3
#     SAMPLE_filter3_genes.aa
#     SAMPLE_filter3_genes.cds
#     SAMPLE_filter3_busco.txt
#     SAMPLE_filter3_tiara.txt               (from tiara/<SAMPLE> without extension)
#     SAMPLE_filter3_eggnog_annotations.out
#     SAMPLE_filter3_processed.gff           (from *_gff_processed.txt)
#
# Environment:
#   W=coass_update            (default)
#   DEST_BASE=...             (default: store/final_genomes_${W}_test)
#   The sample list ALWAYS comes from: data/clean/names_${W}.txt

#set -euo pipefail
export LC_ALL=C
shopt -s nullglob

W="${W:-coass_update}"

# Sample list
NFILE="data/clean/names_${W}.txt"
if [[ ! -s "$NFILE" ]]; then
  echo "ERROR: cannot find sample list: $NFILE" >&2
  exit 1
fi

# Destination
DEST_BASE="${DEST_BASE:-store/final_genomes_${W}_test}"
mkdir -p "$DEST_BASE"

# Input paths
F3_ASM_DIR="lustre/filters_clean_${W}/filter3"
BASE3="lustre/aleix_gff_process_big2_${W}_filter3"
F3_GFF_DIR="${BASE3}/final_gff3"
F3_FAA_DIR="${BASE3}/final_faa"
F3_CDS_DIR="${BASE3}/final_cds"
F3_BUSCO_DIR="lustre/qbt_${W}_filter3_ess/busco"
F3_TIARA_DIR="lustre/qbt_${W}_filter3_ess/tiara"
F3_GFF_PROC_DIR="lustre/aleix_gff_${W}_process_out_filter3"
F3_EGGNOG_DIR="lustre/eggnog_${W}_filter3_clean_skip4"

echo "Destination directory: $DEST_BASE"
echo "Using samples from:    $NFILE"

# Counters
total=0
packed_ok=0
packed_warn=0

miss_sca=0
miss_gff=0
miss_faa=0
miss_cds=0
miss_bus=0
miss_tia=0
miss_egg=0
miss_proc=0

# ---------------------------------------------
# MAIN LOOP — read samples line by line
# ---------------------------------------------
while IFS= read -r S; do
  # skip empty lines
  [[ -z "$S" ]] && continue

  ((total++))
  echo "📦 Processing: ${S}"

  DEST="${DEST_BASE}/${S}"
  mkdir -p "$DEST"

  sample_missing=0

  # 1. Scaffolds
  SC="${F3_ASM_DIR}/${S}_filter3_clean.fasta"
  if [[ -f "$SC" ]]; then
    cp -n -- "$SC" "${DEST}/${S}_filter3_scaffolds.fasta"
  else
    echo "  ⚠ Missing filter3 scaffolds"
    ((miss_sca++))
    ((sample_missing++))
  fi

  # 2. GFF3
  GFF="${F3_GFF_DIR}/${S}_filter3.gff3"
  if [[ -f "$GFF" ]]; then
    cp -n -- "$GFF" "${DEST}/${S}_filter3.gff3"
  else
    echo "  ⚠ Missing filter3 gff3"
    ((miss_gff++))
    ((sample_missing++))
  fi

  # 3. FAA
  FAA="${F3_FAA_DIR}/${S}_filter3_genes.faa"
  if [[ -f "$FAA" ]]; then
    cp -n -- "$FAA" "${DEST}/${S}_filter3_genes.aa"
  else
    echo "  ⚠ Missing filter3 faa"
    ((miss_faa++))
    ((sample_missing++))
  fi

  # 4. CDS
  CDS="${F3_CDS_DIR}/${S}_filter3_genes.cds"
  if [[ -f "$CDS" ]]; then
    cp -n -- "$CDS" "${DEST}/${S}_filter3_genes.cds"
  else
    echo "  ⚠ Missing filter3 cds"
    ((miss_cds++))
    ((sample_missing++))
  fi

  # 5. BUSCO
  BUSCO_FILE=$(ls "${F3_BUSCO_DIR}"/short_summary*."${S}".txt 2>/dev/null | head -n1 || true)
  if [[ -n "$BUSCO_FILE" && -f "$BUSCO_FILE" ]]; then
    cp -n -- "$BUSCO_FILE" "${DEST}/${S}_filter3_busco.txt"
  else
    echo "  ⚠ Missing filter3 busco"
    ((miss_bus++))
    ((sample_missing++))
  fi

  # 6. TIARA (no extension)
  TIA="${F3_TIARA_DIR}/${S}"
  if [[ -f "$TIA" ]]; then
    cp -n -- "$TIA" "${DEST}/${S}_filter3_tiara.txt"
  else
    echo "  ⚠ Missing filter3 tiara"
    ((miss_tia++))
    ((sample_missing++))
  fi

  # 7. eggNOG
  EGG="${F3_EGGNOG_DIR}/${S}_eggnog.emapper.annotations_clean"
  if [[ -f "$EGG" ]]; then
    cp -n -- "$EGG" "${DEST}/${S}_filter3_eggnog_annotations.out"
  else
    echo "  ⚠ Missing filter3 eggnog"
    ((miss_egg++))
    ((sample_missing++))
  fi

  # 8. processed GFF
  PROC="${F3_GFF_PROC_DIR}/${S}_gff_processed.txt"
  if [[ -f "$PROC" ]]; then
    cp -n -- "$PROC" "${DEST}/${S}_filter3_processed.gff"
  else
    echo "  ⚠ Missing filter3 processed gff"
    ((miss_proc++))
    ((sample_missing++))
  fi

  # sample summary
  if (( sample_missing == 0 )); then
    ((packed_ok++))
  else
    ((packed_warn++))
  fi

done < "$NFILE"

# ---------------------------------------------
# FINAL REPORT
# ---------------------------------------------
echo
echo "✅ Finished → $DEST_BASE"
echo "Total samples:      $total"
echo "Fully complete:     $packed_ok"
echo "With warnings:      $packed_warn"
echo
echo "Missing files summary:"
echo "  scaffolds:        $miss_sca"
echo "  gff3:             $miss_gff"
echo "  faa:              $miss_faa"
echo "  cds:              $miss_cds"
echo "  busco:            $miss_bus"
echo "  tiara:            $miss_tia"
echo "  eggnog:           $miss_egg"
echo "  processed gff:    $miss_proc"
