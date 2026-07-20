#!/bin/bash

set -u

W=coass_guigo

# Base for filter3 build (override with: BASE=... bash script.sh)
BASE="${BASE:-lustre/aleix_gff_process_big2_${W}_filter3}"
mkdir -p "${BASE}/logs"

# Default species file is ./x (override with: SPEC3=... bash script.sh)
SPEC3="${SPEC3:-${BASE}/species3.txt}"
[[ -f "$SPEC3" ]] || { echo "No species list found: $SPEC3"; exit 1; }

# ---- Conda env (AGAT) ----
module load cesga/system miniconda3/22.11.1-1
source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate agat
command -v agat_sp_keep_longest_isoform.pl >/dev/null || { echo "AGAT not found in env"; exit 3; }

process_filter3 () {
  local SPECIES="$1"

  local ASM_DIR_CLEAN="${BASE}/assemblies3_clean"
  local ASM_DIR_RAW="${BASE}/assemblies3"
  local GTF_DIR_CLEAN="${BASE}/gtf3_clean"
  local GTF_DIR_RAW="${BASE}/gtf3"
  local OUT_ROOT="${BASE}/results_f3_50aa"
  local LENGTH_AA=50
  local LENGTH_NT=$((LENGTH_AA * 3))

  # prefer clean inputs
  local ASM_DIR="$ASM_DIR_CLEAN"; [[ -d "$ASM_DIR" ]] || ASM_DIR="$ASM_DIR_RAW"
  local GTF_DIR="$GTF_DIR_CLEAN"; [[ -d "$GTF_DIR" ]] || GTF_DIR="$GTF_DIR_RAW"

  local ASSEMBLY="${ASM_DIR}/${SPECIES}.fasta"
  local GTF_IN="${GTF_DIR}/${SPECIES}.gtf"

  if [[ ! -f "$ASSEMBLY" || ! -f "$GTF_IN" ]]; then
    echo "⚠️  filter3: missing files for ${SPECIES} -> assembly? $( [[ -f "$ASSEMBLY" ]] && echo ok || echo missing ), gtf? $( [[ -f "$GTF_IN" ]] && echo ok || echo missing ). Skipping."
    return 0
  fi

  local OUT_DIR="${OUT_ROOT}/${SPECIES}"
  local PREF="${OUT_DIR}/${SPECIES}"

  # Optional reset for this species (export RESET_RESULTS=1 to wipe previous)
  if [[ "${RESET_RESULTS:-0}" == "1" && -d "$OUT_DIR" ]]; then
    local SAFE_BASE OUT_REAL
    SAFE_BASE="$(realpath "${OUT_ROOT}")"
    OUT_REAL="$(realpath "$OUT_DIR")"
    case "$OUT_REAL" in
      "$SAFE_BASE"/*) echo "🔁 Resetting outputs: rm -rf \"$OUT_DIR\""; rm -rf -- "$OUT_DIR" ;;
      *) echo "❌ Refusing to delete unexpected path: $OUT_DIR"; return 2 ;;
    esac
  fi

  mkdir -p "$OUT_DIR"

  echo "=== ${SPECIES} (filter3 only) ==="
  echo "--- filter3 ---"
  echo "Assembly : ${ASSEMBLY}"
  echo "GTF in   : ${GTF_IN}"
  echo "Out dir  : ${OUT_DIR}"
  echo "Filter   : ≥${LENGTH_AA} aa (${LENGTH_NT} nt)"

  # 1) Basic stats on input GTF
  agat_sq_stat_basic.pl -i "${GTF_IN}" -o "${PREF}_basic_stats.txt"

  # 2) Longest isoform (GTF -> GFF3)
  local LONGISO_GFF3="${PREF}_longisoforms.gff3"
  agat_sp_keep_longest_isoform.pl -gff "${GTF_IN}" -o "${LONGISO_GFF3}"

  # 3) Filter by total exon length ≥150 nt
  local FILTERED_GFF3="${PREF}_longisoforms_${LENGTH_NT}plus.gff3"
  agat_sp_filter_gene_by_length.pl \
    -gff "${LONGISO_GFF3}" \
    --size "${LENGTH_NT}" --test ">=" \
    -o "${FILTERED_GFF3}"

  # 4a) Filtered contigs must exist in ORIGINAL GTF
  local GTF_CONTIGS="${OUT_DIR}/orig_gtf.contigs"
  local FILT_CONTIGS="${OUT_DIR}/filt_gff3.contigs"
  grep -v '^#' "${GTF_IN}"        | cut -f1 | sort -u > "${GTF_CONTIGS}"
  grep -v '^#' "${FILTERED_GFF3}" | cut -f1 | sort -u > "${FILT_CONTIGS}"

  local MISSING_IN_ORIG
  MISSING_IN_ORIG=$(comm -23 "${FILT_CONTIGS}" "${GTF_CONTIGS}" || true)
  if [[ -n "${MISSING_IN_ORIG}" ]]; then
    echo "❌ filter3: filtered contigs not present in original GTF:"
    printf '%s\n' "${MISSING_IN_ORIG}"
    return 1
  else
    echo "✅ filter3: filtered contigs ⊆ original GTF contigs"
  fi

  # 4b) Filtered contigs must exist in ASSEMBLY
  local ASM_CONTIGS="${OUT_DIR}/assembly.contigs"
  grep '^>' "${ASSEMBLY}" | sed 's/^>//; s/[ \t].*$//' | sort -u > "${ASM_CONTIGS}"

  local MISSING_IN_ASM
  MISSING_IN_ASM=$(comm -23 "${FILT_CONTIGS}" "${ASM_CONTIGS}" || true)
  if [[ -n "${MISSING_IN_ASM}" ]]; then
    echo "❌ filter3: filtered contigs not present in assembly FASTA:"
    printf '%s\n' "${MISSING_IN_ASM}"
    return 1
  else
    echo "✅ filter3: filtered contigs ⊆ assembly contigs"
  fi

  # 5) Stats on filtered GFF3
  agat_sq_stat_basic.pl -i "${FILTERED_GFF3}" -o "${PREF}_longisoforms_${LENGTH_NT}plus_basic_stats.txt"

  # 6) Extract sequences (CDS + AA)
  agat_sp_extract_sequences.pl \
    -f "${ASSEMBLY}" \
    -g "${FILTERED_GFF3}" \
    -t cds \
    -o "${PREF}_longisoforms_${LENGTH_NT}plus_cds.fasta" \
    --merge

  agat_sp_extract_sequences.pl \
    -f "${ASSEMBLY}" \
    -g "${FILTERED_GFF3}" \
    -p \
    -o "${PREF}_longisoforms_${LENGTH_NT}plus.faa" \
    --merge \
    --clean_final_stop

  echo "✔ Done ${SPECIES} (filter3)"
}

run_species_by_name () {
  local SPECIES="$1"
  [[ -z "$SPECIES" ]] && return 0
  process_filter3 "$SPECIES" || echo "⚠️  filter3 finished with warnings/errors for ${SPECIES}"
}

run_species_by_line () {
  local LINE_NO="$1"
  local SPECIES
  SPECIES="$(sed -n "${LINE_NO}p" "$SPEC3" | tr -d '\r')"

  if [[ -z "${SPECIES}" ]]; then
    echo "⚠️  No species at line ${LINE_NO} in ${SPEC3}. Skipping."
    return 0
  fi

  run_species_by_name "$SPECIES"
}

# -----------------------------
# Command-line behavior
# -----------------------------
#
# No arguments:
#   run all species in x
#
# Numeric arguments:
#   treat them as line numbers in x
#   example: bash script.sh 29 42 45 46
#
# --species NAME [NAME2 ...]:
#   run specific species names directly
#   example: bash script.sh --species ICM0065_COSAG.1_Prymnesiophyceae
#

if [[ $# -eq 0 ]]; then
  while IFS= read -r SPECIES || [[ -n "$SPECIES" ]]; do
    SPECIES="$(printf '%s' "$SPECIES" | tr -d '\r')"
    [[ -z "$SPECIES" ]] && continue
    run_species_by_name "$SPECIES"
  done < "$SPEC3"

elif [[ "$1" == "--species" ]]; then
  shift
  if [[ $# -eq 0 ]]; then
    echo "Usage:"
    echo "  bash $0                  # run all species from x"
    echo "  bash $0 29 42 45 46      # run selected line numbers from x"
    echo "  bash $0 --species NAME   # run one or more species names directly"
    conda deactivate
    exit 1
  fi

  for SPECIES in "$@"; do
    run_species_by_name "$SPECIES"
  done

else
  for ARG in "$@"; do
    if [[ "$ARG" =~ ^[0-9]+$ ]]; then
      run_species_by_line "$ARG"
    else
      echo "⚠️  Argument '$ARG' is not a number."
      echo "Use either:"
      echo "  bash $0                  # run all species from x"
      echo "  bash $0 29 42 45 46      # run selected line numbers from x"
      echo "  bash $0 --species NAME   # run species names directly"
    fi
  done
fi

conda deactivate
echo "✔ All done"
