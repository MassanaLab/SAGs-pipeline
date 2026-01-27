#!/bin/bash

#SBATCH --job-name=process_gtf_50aa_f3_only
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=6
#SBATCH --mem=12G
#SBATCH --time=00:30:00
#SBATCH --output=data/logs/process_gtf_f3_%A_%a.out
#SBATCH --error=data/logs/process_gtf_f3_%A_%a.err
#SBATCH --array=1-2%2

W=coass_update

# Base for filter3
BASE="lustre/aleix_gff_process_big2_${W}_filter3"
mkdir -p "${BASE}/logs"

SPEC3="${BASE}/species3.txt"
[[ -f "$SPEC3" ]] || { echo "No species list found: $SPEC3"; exit 1; }

# Map array index to species from species3.txt
SPECIES="$(awk "NR==${SLURM_ARRAY_TASK_ID}" "$SPEC3" | tr -d '\r')"
[[ -n "${SPECIES:-}" ]] || { echo "No species at index ${SLURM_ARRAY_TASK_ID} in species3.txt"; exit 0; }

echo "=== ${SPECIES} (filter3 only) ==="

# Conda enviroment
module load cesga/system miniconda3/22.11.1-1
source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate agat
command -v agat_sp_keep_longest_isoform.pl >/dev/null || { echo "AGAT not found in env"; exit 3; }

# Process filter3 for this SPECIES
process_filter3 () {
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
    SAFE_BASE="$(realpath "${OUT_ROOT}")"
    OUT_REAL="$(realpath "$OUT_DIR")"
    case "$OUT_REAL" in
      "$SAFE_BASE"/*) echo "🔁 Resetting outputs: rm -rf \"$OUT_DIR\""; rm -rf -- "$OUT_DIR" ;;
      *) echo "❌ Refusing to delete unexpected path: $OUT_DIR"; exit 2 ;;
    esac
  fi

  mkdir -p "$OUT_DIR"

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

process_filter3 || echo "⚠️  filter3 finished with warnings/errors for ${SPECIES}"
conda deactivate
echo "✔ All done for ${SPECIES} (filter3 only)"
