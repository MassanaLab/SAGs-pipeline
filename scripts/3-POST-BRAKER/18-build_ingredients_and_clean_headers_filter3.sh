#!/usr/bin/env bash

set -euo pipefail
export LC_ALL=C

W=coass_update

# Inputs (override via args if needed)

LIST="data/clean/names_${W}.txt"
ASM_DIR="lustre/filters_clean_${W}/filter3"
GTF_DIR="store/braker3_${W}_post_filter3/gtf"
OUT_BASE="lustre/aleix_gff_process_big2_${W}_filter3"

[[ -f "$LIST" ]] || { echo "ERROR: sample list not found: $LIST" >&2; exit 1; }

# --- RESET OUTPUT BASE ---
if [[ -d "$OUT_BASE" ]]; then
  echo "🧹 Removing existing $OUT_BASE"
  rm -rf --one-file-system -- "$OUT_BASE"
fi

ASM3="${OUT_BASE}/assemblies3"
GTF3="${OUT_BASE}/gtf3"
ASM3C="${OUT_BASE}/assemblies3_clean"
GTF3C="${OUT_BASE}/gtf3_clean"

SPEC3="${OUT_BASE}/species3.txt"
MISS_A3="${OUT_BASE}/_missing_filter3_assembly.txt"
MISS_G3="${OUT_BASE}/_missing_filter3_gtf.txt"

mkdir -p "$ASM3" "$GTF3" "$ASM3C" "$GTF3C"
: > "$SPEC3"; : > "$MISS_A3"; : > "$MISS_G3"

# Counters
CNT_TOTAL=0; CNT_OK=0; CNT_MISS_ASM=0; CNT_MISS_GTF=0

clean_fasta_to_node() {
  # Keep only ID (up to first space/tab), if it contains NODE_ keep from NODE_
  awk '(/^>/){hdr=$0; sub(/^>/,"",hdr); sub(/[ \t].*$/,"",hdr);
             p=index(hdr,"NODE_"); print ">" ((p>0)?substr(hdr,p):hdr); next} {print}' "$1" > "$2"
}
clean_gtf_to_node() {
  awk 'BEGIN{OFS="\t"}
    /^##sequence-region[ \t]+/ {p=index($2,"NODE_"); if(p>0)$2=substr($2,p); print; next}
    /^##/||/^#/ {print; next}
    {p=index($1,"NODE_"); if(p>0)$1=substr($1,p); print}' "$1" > "$2"
}
sanity_check_pair() {
  local sp="$1" fa="$2" gtf="$3"
  local tmpg="/tmp/${sp}.gtf.c" tmpf="/tmp/${sp}.fa.c"
  grep -v '^#' "$gtf" | cut -f1 | sort -u > "$tmpg"
  grep '^>'   "$fa"  | sed 's/^>//; s/[ \t].*$//' | sort -u > "$tmpf"
  local miss; miss=$(comm -23 "$tmpg" "$tmpf" || true)
  if [[ -n "$miss" ]]; then
    echo "❗ ${sp}: GTF contigs missing in FASTA"; printf '%s\n' "$miss" | sed 's/^/   /'
  else
    echo "✅ ${sp}: GTF contigs all present"
  fi
}

echo "🎬 == Building filter3 from list: $LIST =="
while IFS= read -r sample; do
  [[ -z "$sample" ]] && continue
  ((CNT_TOTAL++)) || true

  asm="${ASM_DIR}/${sample}_filter3_clean.fasta"
  gtf="${GTF_DIR}/${sample}_augustus.hints.gtf"

  if [[ ! -s "$asm" ]]; then
    echo "$sample" >> "$MISS_A3"
    echo "❌ $sample (missing/empty ASM): $asm"
    ((CNT_MISS_ASM++)) || true
    continue
  fi
  if [[ ! -s "$gtf" ]]; then
    echo "$sample" >> "$MISS_G3"
    echo "❌ $sample (missing/empty GTF): $gtf"
    ((CNT_MISS_GTF++)) || true
    continue
  fi

  echo "🧬 $sample ASM: $asm"
  echo "🧠 $sample GTF: $gtf"

  # Stage originals
  cp -f "$asm" "${ASM3}/${sample}.fasta"
  cp -f "$gtf" "${GTF3}/${sample}.gtf"

  # Clean headers to NODE_*
  echo "🧼 $sample cleaning headers → NODE_*"
  clean_fasta_to_node "${ASM3}/${sample}.fasta" "${ASM3C}/${sample}.fasta"
  clean_gtf_to_node   "${GTF3}/${sample}.gtf"   "${GTF3C}/${sample}.gtf"

  # Sanity check: all GTF contigs exist in FASTA
  sanity_check_pair "$sample" "${ASM3C}/${sample}.fasta" "${GTF3C}/${sample}.gtf"

  echo "$sample" >> "$SPEC3"
  ((CNT_OK++)) || true
  echo "✅ Done: $sample"
  echo
done < "$LIST"

sort -u -o "$SPEC3" "$SPEC3"

echo "------ 📊 SUMMARY ------"
echo "Output base: $OUT_BASE"
echo "  🧬 Samples listed:          ${CNT_TOTAL}"
echo "  ✅ Successfully processed:   ${CNT_OK}"
echo "  ❌ Missing ASM:              ${CNT_MISS_ASM}  -> $MISS_A3"
echo "  ❌ Missing GTF:              ${CNT_MISS_GTF}  -> $MISS_G3"
echo "Files:"
echo "  • species3.txt:              $(wc -l < "$SPEC3")"
echo "  • assemblies3_clean/:        $(ls -1 "$ASM3C" 2>/dev/null | wc -l)"
echo "  • gtf3_clean/:               $(ls -1 "$GTF3C" 2>/dev/null | wc -l)"
