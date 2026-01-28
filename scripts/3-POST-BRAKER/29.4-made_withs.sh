#!/usr/bin/env bash
# 3X.9-copy_made_with.sh
#
# For each file in:
#   lustre/made_withs_R/<sample>_made_with_*.txt
#
# copy it to:
#   store/final_genomes_${W}/<sample>/<same filename>
#
# No renaming, no editing.


W="coass_update"

SRC_DIR="lustre/made_withs_R"
DEST_BASE="store/final_genomes_${W}_test"

echo "Source dir:      $SRC_DIR"
echo "Destination dir: $DEST_BASE"
echo

copied=0
missing_dir=0

for f in "$SRC_DIR"/*_made_with_*SAGs.txt; do
  [[ -e "$f" ]] || continue

  bn="${f##*/}"                                # full filename
  sample="${bn%_made_with_*}"                  # strip "_made_with_...SAGs.txt"
  dest_dir="${DEST_BASE}/${sample}"
  dest_file="${dest_dir}/${bn}"

  if [[ -d "$dest_dir" ]]; then
    echo "COPY: $bn  ->  $sample/"
    cp -n -- "$f" "$dest_file"
    ((copied++))
  else
    echo "SKIP: $bn (no dest dir: $dest_dir)"
    ((missing_dir++))
  fi
done

echo
echo "✅ Done."
echo "  Files copied:        $copied"
echo "  Missing dest folders: $missing_dir"
