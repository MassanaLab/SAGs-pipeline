#!/bin/bash
# Copy post-filter (150plus) results into final_faa/ and final_gff3/,
# renaming to SAMPLE_filter{1,3}_genes.faa and SAMPLE_filter{1,3}.gff3.

W=coass_update

BASE="lustre/aleix_gff_process_big2_${W}_filter3"
LIST="${BASE}/species3.txt"

DEST_FAA="${BASE}/final_faa"
DEST_GFF3="${BASE}/final_gff3"

# --- reset destinations ---
rm -rf -- "$DEST_FAA" "$DEST_GFF3"
mkdir -p "$DEST_FAA" "$DEST_GFF3"

# --- load samples (strip CRLF + blanks) ---
[[ -s "$LIST" ]] || { echo "No species list: $LIST" >&2; exit 1; }
mapfile -t SAMPLES < <(sed -e 's/\r$//' -e '/^[[:space:]]*$/d' "$LIST")
TOT=${#SAMPLES[@]}
(( TOT > 0 )) || { echo "No samples after sanitization." >&2; exit 1; }

# --- counters ---
c_f1_faa=0; c_f3_faa=0; c_f1_gff=0; c_f3_gff=0
m_f1_faa=0; m_f3_faa=0; m_f1_gff=0; m_f3_gff=0

copy_as() {
  # args: src dest &copied &missing
  local src="$1" dest="$2" _cop="$3" _miss="$4"
  if [[ -f "$src" ]]; then
    cp -f -- "$src" "$dest" || { echo "WARN: failed to copy $src -> $dest" >&2; return 0; }
    printf -v "$_cop" '%d' "$(( ${!_cop} + 1 ))"
  else
    printf -v "$_miss" '%d' "$(( ${!_miss} + 1 ))"
  fi
}

for ((i=0; i<TOT; i++)); do
  S="${SAMPLES[i]}"
  printf "⏳ [%3d%%] %s\n" $(( (i+1)*100 / TOT )) "$S" >&2

  f1_dir="${BASE}/results_f1_50aa/${S}"
  f3_dir="${BASE}/results_f3_50aa/${S}"

  # FAA
  copy_as "${f1_dir}/${S}_longisoforms_150plus.faa"  "${DEST_FAA}/${S}_filter1_genes.faa"  c_f1_faa m_f1_faa
  copy_as "${f3_dir}/${S}_longisoforms_150plus.faa"  "${DEST_FAA}/${S}_filter3_genes.faa"  c_f3_faa m_f3_faa

  # GFF3
  copy_as "${f1_dir}/${S}_longisoforms_150plus.gff3" "${DEST_GFF3}/${S}_filter1.gff3"      c_f1_gff m_f1_gff
  copy_as "${f3_dir}/${S}_longisoforms_150plus.gff3" "${DEST_GFF3}/${S}_filter3.gff3"      c_f3_gff m_f3_gff
done

echo "------ 📦 COPY SUMMARY ------"
echo "Samples listed:                $TOT"
echo "final_faa:   f1 copied=${c_f1_faa}, f3 copied=${c_f3_faa}, f1 missing=${m_f1_faa}, f3 missing=${m_f3_faa}   → ${DEST_FAA}"
echo "final_gff3:  f1 copied=${c_f1_gff}, f3 copied=${c_f3_gff}, f1 missing=${m_f1_gff}, f3 missing=${m_f3_gff}   → ${DEST_GFF3}"
