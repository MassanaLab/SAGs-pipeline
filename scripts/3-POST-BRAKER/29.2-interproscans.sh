#!/usr/bin/env bash
# 3X.?.-interproscan_filter_and_collect.sh
#
# For each InterProScan TSV in IN_DIR:
#   1) Create a PFAM-only TSV (keep header + lines where col 4 contains "Pfam")
#      into PFAM_DIR as: <sample>_pfam.tsv
#   2) Copy PFAM-only TSV into:
#        DEST_BASE/<sample>/<sample>_filter3_interproscan_pfam.tsv
#   3) Copy full TSV into:
#        DEST_BASE/<sample>/<sample>_filter3_interproscan.tsv
#
# Environment (optional):
#   W=coass_update                    (default)
#   IN_DIR=lustre/interproscan_temp   (default)
#   PFAM_DIR=lustre/interproscan_temp_pfam_only
#   DEST_BASE=store/final_genomes_${W}


W="coass_update"

IN_DIR="${IN_DIR:-lustre/interproscan_temp}"
PFAM_DIR="${PFAM_DIR:-lustre/interproscan_temp_pfam_only}"
DEST_BASE="${DEST_BASE:-store/final_genomes_${W}_test}"

mkdir -p "$PFAM_DIR"

echo "Input TSV dir:      $IN_DIR"
echo "PFAM-only dir:      $PFAM_DIR"
echo "Final genomes dir:  $DEST_BASE"
echo

# ---------------------------------------------
# 1) Build PFAM-only TSVs from InterProScan TSVs
# ---------------------------------------------
found_any=false

for f in "$IN_DIR"/*.tsv; do
  [[ -e "$f" ]] || continue
  found_any=true

  bn="$(basename "$f")"              # e.g. ICM0001_....tsv
  out="${PFAM_DIR}/${bn%.tsv}_pfam.tsv"

  echo "PFAM filter: $bn  ->  $(basename "$out")"
  awk -F'\t' 'NR==1 || tolower($4) ~ /pfam/' "$f" > "$out"
done

if ! $found_any; then
  echo "No .tsv files found in $IN_DIR" >&2
  echo "Done (nothing to do)."
  exit 0
fi

echo
echo "PFAM-only generation finished."
echo

# ---------------------------------------------
# 2) Copy PFAM-only TSVs into final genomes folders
# ---------------------------------------------
for f in "$PFAM_DIR"/*_pfam.tsv; do
  [[ -e "$f" ]] || continue

  bn="${f##*/}"                      # basename
  sample="${bn%_pfam.tsv}"           # remove _pfam.tsv
  dest_dir="${DEST_BASE}/${sample}"
  dest_file="${dest_dir}/${sample}_filter3_interproscan_pfam.tsv"

  if [[ -d "$dest_dir" ]]; then
    echo "PFAM copy: $bn  ->  ${sample}_filter3_interproscan_pfam.tsv"
    cp -n -- "$f" "$dest_file"
  else
    echo "SKIP PFAM: $sample (no dest dir: $dest_dir)"
  fi
done

echo
echo "PFAM copies to final genomes finished."
echo

# ---------------------------------------------
# 3) Copy full InterProScan TSVs into final genomes folders
# ---------------------------------------------
for f in "$IN_DIR"/*.tsv; do
  [[ -e "$f" ]] || continue

  bn="${f##*/}"                      # basename
  sample="${bn%.tsv}"                # remove .tsv
  dest_dir="${DEST_BASE}/${sample}"
  dest_file="${dest_dir}/${sample}_filter3_interproscan.tsv"

  if [[ -d "$dest_dir" ]]; then
    echo "IPR copy:  $bn  ->  ${sample}_filter3_interproscan.tsv"
    cp -n -- "$f" "$dest_file"
  else
    echo "SKIP IPR : $sample (no dest dir: $dest_dir)"
  fi
done

echo
echo "✅ Done. PFAM-only in: $PFAM_DIR"
echo "   Full and PFAM InterProScan TSVs copied into: $DEST_BASE"
