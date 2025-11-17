#!/usr/bin/env bash
# 3X.1.1-filter1_initial.sh
#
# For each SAMPLE, create:
#   store/final_genomes_${W}/${SAMPLE}/
#     SAMPLE_filter1_tiara.txt
#     SAMPLE_filter1_busco.txt
#     SAMPLE_filter1_eggnog_annotations.out
#     SAMPLE_filter1_genes.aa
#     SAMPLE_filter1_genes.cds
#     SAMPLE_filter1_kaiju_faa_names.out
#     SAMPLE_filter1_scaffolds.fasta
#     SAMPLE_filter1.gff3
#     SAMPLE_filter1_processed.gff
#     SAMPLE_og_scaffolds.fasta      # original SPAdes assembly
#
# Environment:
#   W=coass_update (default)
#   DEST_BASE=... (default: store/final_genomes_${W}_test)
#   Sample list always comes from: data/clean/names_${W}.txt

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
SPADES_DIR="lustre/spades_${W}"
BASE1="lustre/aleix_gff_process_big2_${W}"
F1_ASM_CLEAN_DIR="${BASE1}/assemblies1_clean"
F1_GFF_FINAL_DIR="${BASE1}/final_gff3"
F1_GFF_PROC_DIR="lustre/aleix_gff_${W}_process_out"
F1_FAA_FINAL_DIR="${BASE1}/final_faa"
F1_CDS_FINAL_DIR="${BASE1}/final_cds"
F1_EGGNOG_DIR="lustre/eggnog_${W}_clean_skip4"
F1_KAIJU_DIR="lustre/kaiju_${W}_grep_C"
F1_BUSCO_DIR="lustre/qbt_${W}_filter1_ess/busco"
F1_TIARA_DIR="lustre/qbt_${W}_filter1_ess/tiara"

echo "Destination directory: $DEST_BASE"
echo "Using samples from:    $NFILE"

# Counters
total=0
packed_ok=0
packed_warn=0

miss_tia=0
miss_bus=0
miss_egg=0
miss_faa=0
miss_cds=0
miss_kai=0
miss_sca=0
miss_gff=0
miss_gffp=0
miss_og=0

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

  # 1. TIARA (file without extension, exact sample name)
  TIA="${F1_TIARA_DIR}/${S}"
  if [[ -f "$TIA" ]]; then
    cp -n -- "$TIA" "${DEST}/${S}_filter1_tiara.txt"
  else
    echo "  ⚠ Missing tiara"
    ((miss_tia++))
    ((sample_missing++))
  fi

  # 2. BUSCO (short_summary*.<S>.txt)
  BUSCO_FILE=$(ls "${F1_BUSCO_DIR}"/short_summary*."${S}".txt 2>/dev/null | head -n1 || true)
  if [[ -n "$BUSCO_FILE" && -f "$BUSCO_FILE" ]]; then
    cp -n -- "$BUSCO_FILE" "${DEST}/${S}_filter1_busco.txt"
  else
    echo "  ⚠ Missing busco"
    ((miss_bus++))
    ((sample_missing++))
  fi

  # 3. eggNOG (fixed name)
  EGG="${F1_EGGNOG_DIR}/${S}_eggnog.emapper.annotations_clean"
  if [[ -f "$EGG" ]]; then
    cp -n -- "$EGG" "${DEST}/${S}_filter1_eggnog_annotations.out"
  else
    echo "  ⚠ Missing eggnog"
    ((miss_egg++))
    ((sample_missing++))
  fi

  # 4. FAA
  FAA="${F1_FAA_FINAL_DIR}/${S}_filter1_genes.faa"
  if [[ -f "$FAA" ]]; then
    cp -n -- "$FAA" "${DEST}/${S}_filter1_genes.aa"
  else
    echo "  ⚠ Missing faa"
    ((miss_faa++))
    ((sample_missing++))
  fi

  # 5. CDS
  CDS="${F1_CDS_FINAL_DIR}/${S}_filter1_genes.cds"
  if [[ -f "$CDS" ]]; then
    cp -n -- "$CDS" "${DEST}/${S}_filter1_genes.cds"
  else
    echo "  ⚠ Missing cds"
    ((miss_cds++))
    ((sample_missing++))
  fi

  # 6. Kaiju
  KAI="${F1_KAIJU_DIR}/${S}_kaiju_faa_names_grep_C.out"
  if [[ -f "$KAI" ]]; then
    cp -n -- "$KAI" "${DEST}/${S}_filter1_kaiju_faa_names.out"
  else
    echo "  ⚠ Missing kaiju"
    ((miss_kai++))
    ((sample_missing++))
  fi

  # 7. Clean filter1 scaffolds
  SCAFF="${F1_ASM_CLEAN_DIR}/${S}.fasta"
  if [[ -f "$SCAFF" ]]; then
    cp -n -- "$SCAFF" "${DEST}/${S}_filter1_scaffolds.fasta"
  else
    echo "  ⚠ Missing filter1 scaffolds"
    ((miss_sca++))
    ((sample_missing++))
  fi

  # 8. Original SPAdes assembly (OG scaffolds)
  OG1="${SPADES_DIR}/${S}_scaffolds.fasta"
  OG2="${SPADES_DIR}/${S}_contigs.fasta"

  if [[ -s "$OG1" ]]; then
    cp -n -- "$OG1" "${DEST}/${S}_og_scaffolds.fasta"
  elif [[ -s "$OG2" ]]; then
    cp -n -- "$OG2" "${DEST}/${S}_og_scaffolds.fasta"
  else
    echo "  ⚠ Missing OG assembly (spades_${W})"
    ((miss_og++))
    ((sample_missing++))
  fi

  # 9. Final filter1 GFF3
  GFF="${F1_GFF_FINAL_DIR}/${S}_filter1.gff3"
  if [[ -f "$GFF" ]]; then
    cp -n -- "$GFF" "${DEST}/${S}_filter1.gff3"
  else
    echo "  ⚠ Missing gff3"
    ((miss_gff++))
    ((sample_missing++))
  fi

  # 10. Processed GFF (filter1)
  GFFP="${F1_GFF_PROC_DIR}/${S}_gff_processed.txt"
  if [[ ! -f "$GFFP" ]]; then
    # fallback: any file that starts with SAMPLE and ends with _gff_processed.txt
    GFFP=$(ls "${F1_GFF_PROC_DIR}/${S}"*_gff_processed.txt 2>/dev/null | head -n1 || true)
  fi

  if [[ -n "${GFFP:-}" && -f "$GFFP" ]]; then
    cp -n -- "$GFFP" "${DEST}/${S}_filter1_processed.gff"
  else
    echo "  ⚠ Missing processed gff"
    ((miss_gffp++))
    ((sample_missing++))
  fi

  # Per-sample summary
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
echo "  tiara:            $miss_tia"
echo "  busco:            $miss_bus"
echo "  eggnog:           $miss_egg"
echo "  faa:              $miss_faa"
echo "  cds:              $miss_cds"
echo "  kaiju:            $miss_kai"
echo "  scaffolds:        $miss_sca"
echo "  OG assembly:      $miss_og"
echo "  gff3:             $miss_gff"
echo "  processed gff:    $miss_gffp"
