#!/bin/bash

#SBATCH --job-name=process_gtf_50aa_f1_only
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=6
#SBATCH --mem=12G
#SBATCH --time=00:30:00
#SBATCH --output=data/logs/process_gtf_f1_%A_%a.out
#SBATCH --error=data/logs/process_gtf_f1_%A_%a.err
#SBATCH --array=1-2%2

set -euo pipefail
export LC_ALL=C

W=coass_update

# Point to your current BASE (you can override via: BASE=... sbatch ...)
BASE="lustre/aleix_gff_process_big2_${W}"
mkdir -p "${BASE}/logs"

SPEC1="${BASE}/species1.txt"
[[ -f "$SPEC1" ]] || { echo "No species list found: $SPEC1"; exit 1; }

# Map array index -> species from species1.txt
SPECIES="$(awk "NR==${SLURM_ARRAY_TASK_ID}" "$SPEC1" | tr -d '\r')"
[[ -n "${SPECIES:-}" ]] || { echo "No species at index ${SLURM_ARRAY_TASK_ID} in species1.txt"; exit 0; }

echo "=== ${SPECIES} (filter1 only) ==="

# Conda enviroment (AGAT)
module load cesga/system miniconda3/22.11.1-1
source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate agat
command -v agat_sp_keep_longest_isoform.pl >/dev/null || { echo "AGAT not found in env"; exit 3; }

# Process filter1 for this SPECIES
process_filter1 () {
  local ASM_DIR_CLEAN="${BASE}/assemblies1_clean"
  local ASM_DIR_RAW="${BASE}/assemblies1"
  local GTF_DIR_CLEAN="${BASE}/gtf1_clean"
  local GTF_DIR_RAW="${BASE}/gtf1"
  local OUT_ROOT="${BASE}/results_f1_50aa"
  local LENGTH_AA=50
  local LENGTH_NT=$((LENGTH_AA * 3))

  # prefer clean inputs
  local ASM_DIR="$ASM_DIR_CLEAN"; [[ -d "$ASM_DIR" ]] || ASM_DIR="$ASM_DIR_RAW"
  local GTF_DIR="$GTF_DIR_CLEAN"; [[ -d "$GTF_DIR" ]] || GTF_DIR="$GTF_DIR_RAW"

  local ASSEMBLY="${ASM_DIR}/${SPECIES}.fasta"
  local GTF_IN="${GTF_DIR}/${SPECIES}.gtf"

  if [[ ! -f "$ASSEMBLY" || ! -f "$GTF_IN" ]]; then
    echo "⚠️  filter1: missing files for ${SPECIES} -> assembly? $( [[ -f "$ASSEMBLY" ]] && echo ok || echo missing ), gtf? $( [[ -f "$GTF_IN" ]] && echo ok || echo missing ). Skipping."
    return 0
  fi

  local OUT_DIR="${OUT_ROOT}/${SPECIES}"
  local PREF="${OUT_DIR}/${SPECIES}"

  # Optional reset for this species (set RESET_RESULTS=1 when submitting to wipe previous results)
  if [[ "${RESET_RESULTS:-0}" == "1" && -d "$OUT_DIR" ]]; then
    SAFE_BASE="$(realpath "${OUT_ROOT}")"
    OUT_REAL="$(realpath "$OUT_DIR")"
    case "$OUT_REAL" in
      "$SAFE_BASE"/*) echo "🔁 Resetting outputs: rm -rf \"$OUT_DIR\""; rm -rf -- "$OUT_DIR" ;;
      *) echo "❌ Refusing to delete unexpected path: $OUT_DIR"; exit 2 ;;
    esac
  fi

  mkdir -p "$OUT_DIR"

  echo "--- filter1 ---"
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
    echo "❌ filter1: filtered contigs not present in original GTF:"
    printf '%s\n' "${MISSING_IN_ORIG}"
    return 1
  else
    echo "✅ filter1: filtered contigs ⊆ original GTF contigs"
  fi

  # 4b) Filtered contigs must exist in ASSEMBLY
  local ASM_CONTIGS="${OUT_DIR}/assembly.contigs"
  grep '^>' "${ASSEMBLY}" | sed 's/^>//; s/[ \t].*$//' | sort -u > "${ASM_CONTIGS}"
  local MISSING_IN_ASM
  MISSING_IN_ASM=$(comm -23 "${FILT_CONTIGS}" "${ASM_CONTIGS}" || true)
  if [[ -n "${MISSING_IN_ASM}" ]]; then
    echo "❌ filter1: filtered contigs not present in assembly FASTA:"
    printf '%s\n' "${MISSING_IN_ASM}"
    return 1
  else
    echo "✅ filter1: filtered contigs ⊆ assembly contigs"
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

  echo "✔ Done ${SPECIES} (filter1)"
}

process_filter1 || echo "⚠️  filter1 finished with warnings/errors for ${SPECIES}"
conda deactivate
echo "✔ All done for ${SPECIES} (filter1 only)"
