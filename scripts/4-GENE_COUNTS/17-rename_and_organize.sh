#!/usr/bin/env bash

W=coass_update

BASE="lustre/braker3_${W}_post_filter3"
STORE="store/braker3_${W}_post_filter3"
LIST="data/clean/names_${W}.txt"

[[ -f "$LIST" ]] || { echo "ERROR: list not found: $LIST" >&2; exit 1; }

# Make destination folders if they don't exist
mkdir -p "$STORE"/{aa,codingseq,gff3,gtf}

processed=0
missing_dir=0

while IFS= read -r sample; do
  [[ -z "$sample" ]] && continue   # skip empty lines
  d="${BASE}/${sample}"
  if [[ ! -d "$d" ]]; then
    echo "• SKIP (no dir): ${d}"
    ((missing_dir++))
    continue
  fi

  # map old -> new names
  declare -A from_to=(
    ["braker.aa"]="${sample}_augustus.hints.aa"
    ["braker.codingseq"]="${sample}_augustus.hints.codingseq"
    ["braker.gff3"]="${sample}_augustus.hints.gff3"
    ["braker.gtf"]="${sample}_augustus.hints.gtf"
  )

  for src in "${!from_to[@]}"; do
    src_path="$d/$src"
    new_name="${from_to[$src]}"
    tgt_path="$d/$new_name"

    # If already renamed from a previous run, don't mv again
    if [[ -e "$tgt_path" && ! -e "$src_path" ]]; then
      echo "✓ Already renamed: ${tgt_path}"
    elif [[ -e "$src_path" ]]; then
      mv "$src_path" "$tgt_path"
      echo "✓ Renamed: $src_path -> $new_name"
    else
      echo "• Missing: $src_path"
    fi

    # Decide destination folder and copy if file exists
    if [[ -s "$tgt_path" ]]; then
      case "$new_name" in
        *.aa)        dest="$STORE/aa/$new_name" ;;
        *.codingseq) dest="$STORE/codingseq/$new_name" ;;
        *.gff3)      dest="$STORE/gff3/$new_name" ;;
        *.gtf)       dest="$STORE/gtf/$new_name" ;;
        *)           dest="";;
      esac
      if [[ -n "$dest" ]]; then
        cp -f "$tgt_path" "$dest"
        echo "→ Copied: $new_name -> $dest"
      fi
    fi
  done

  ((processed++))
done < "$LIST"

echo
echo "Done. Processed samples: ${processed}. Missing dirs: ${missing_dir}."
echo "Outputs organized under: ${STORE}/(aa|codingseq|gff3|gtf)"
