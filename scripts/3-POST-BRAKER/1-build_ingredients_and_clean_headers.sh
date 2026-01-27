#!/bin/bash

# Project
W=coass_update

# Inputs
ASM_BASE="lustre/${W}_filter1000"
NEW_GTF="store/braker_${W}/gtf"
NEW_GFF3="store/braker_${W}/gff3"

# Output
OUT_BASE="${4:-lustre/aleix_gff_process_big2_${W}}"

# Reset output
if [[ -d "$OUT_BASE" ]]; then
  echo "🧹 Removing existing $OUT_BASE"
  rm -rf --one-file-system -- "$OUT_BASE"
fi

ASM1="${OUT_BASE}/assemblies1"
GTF1="${OUT_BASE}/gtf1"
ASM1C="${OUT_BASE}/assemblies1_clean"
GTF1C="${OUT_BASE}/gtf1_clean"

SPEC1="${OUT_BASE}/species1.txt"
MISS_A1="${OUT_BASE}/_missing_filter1_assembly.txt"
MISS_G1="${OUT_BASE}/_missing_filter1_gtf.txt"

mkdir -p "$ASM1" "$GTF1" "$ASM1C" "$GTF1C"
: > "$SPEC1"; : > "$MISS_A1"; : > "$MISS_G1"

# Counters
CNT_TOTAL=0
CNT_OK=0
CNT_MISS_ASM=0
CNT_MISS_GTF=0
CNT_GTF_BRAKER=0
CNT_GTF_ASM=0

clean_fasta_to_node() {
  awk '(/^>/){hdr=$0; sub(/^>/,"",hdr); split(hdr,a,/[\t ]/); n=a[1]; p=index(n,"NODE_"); print ">" ((p>0)?substr(n,p):n); next} {print}' "$1" > "$2"
}
clean_gtf_to_node() {
  awk 'BEGIN{OFS="\t"}
    /^##sequence-region[ \t]+/ {p=index($2,"NODE_"); if(p>0)$2=substr($2,p); print; next}
    /^##/||/^#/ {print; next}
    {p=index($1,"NODE_"); if(p>0)$1=substr($1,p); print}' "$1" > "$2"
}
sanity_check_pair() {
  local sp="$1" fa="$2" gtf="$3"
  grep -v '^#' "$gtf" | cut -f1 | sort -u > "/tmp/${sp}.gtf.c"
  grep '^>' "$fa" | sed 's/^>//; s/[ \t].*$//' | sort -u > "/tmp/${sp}.fa.c"
  local miss; miss=$(comm -23 "/tmp/${sp}.gtf.c" "/tmp/${sp}.fa.c" || true)
  if [[ -n "$miss" ]]; then
    echo "❗ ${sp}: GTF/GFF contigs missing in FASTA"; printf '%s\n' "$miss" | sed 's/^/   /'
  else
    echo "✅ ${sp}: GTF/GFF contigs all present"
  fi
}

echo "🎬 == Building filter1 with fallback GTFs (project=$W) =="

# Enumerate samples from FASTA files in ASM_BASE (files, not dirs)
# Expected filenames: SAMPLE_filter1000.fasta
while IFS= read -r FASTA_BN; do
  [[ -z "$FASTA_BN" ]] && continue
  SAMPLE="${FASTA_BN%_filter1000.fasta}"
  ((CNT_TOTAL++)) || true

  asm="${ASM_BASE}/${SAMPLE}_filter1000.fasta"
  if [[ ! -f "$asm" ]]; then
    echo "$SAMPLE" >> "$MISS_A1"
    echo "❌ $SAMPLE (no ASM) — looked in: ${ASM_BASE}/"
    ((CNT_MISS_ASM++)) || true
    continue
  fi
  echo "🧬 $SAMPLE ASM: $asm"

  # Prefer new BRAKER GTF; fallback to BRAKER GFF3
  gtf=""; gsrc=""
  for cand in \
    "${NEW_GTF}/${SAMPLE}_augustus.hints.gtf" \
    "${NEW_GFF3}/${SAMPLE}_braker.gff3"
  do
    if [[ -f "$cand" ]]; then
      gtf="$cand"
      gsrc="BRAKER"
      ((CNT_GTF_BRAKER++)) || true
      break
    fi
  done

  if [[ -z "$gtf" ]]; then
    echo "$SAMPLE" >> "$MISS_G1"
    echo "❌ $SAMPLE (no GTF/GFF) — tried ${NEW_GTF}/ and ${NEW_GFF3}/"
    ((CNT_MISS_GTF++)) || true
    continue
  fi

  echo "🧠 $SAMPLE annotation (BRAKER): $gtf"

  cp -f "$asm" "${ASM1}/${SAMPLE}.fasta"
  # Keep target name .gtf even if source is .gff3 (downstream cleaner works for both)
  cp -f "$gtf" "${GTF1}/${SAMPLE}.gtf"

  echo "🧼 $SAMPLE cleaning headers → NODE_*"
  clean_fasta_to_node "${ASM1}/${SAMPLE}.fasta" "${ASM1C}/${SAMPLE}.fasta"
  clean_gtf_to_node   "${GTF1}/${SAMPLE}.gtf"   "${GTF1C}/${SAMPLE}.gtf"
  sanity_check_pair "$SAMPLE" "${ASM1C}/${SAMPLE}.fasta" "${GTF1C}/${SAMPLE}.gtf"

  echo "$SAMPLE" >> "$SPEC1"
  ((CNT_OK++)) || true
  echo "✅ Done: $SAMPLE (GTF source: 🧠 BRAKER)"
  echo
done < <(find "$ASM_BASE" -maxdepth 1 -type f -name '*_filter1000.fasta' -printf '%f\n' | sort)

sort -u -o "$SPEC1" "$SPEC1"

echo "------ 📊 SUMMARY ------"
echo "Project (W):            $W"
echo "ASM base:               $ASM_BASE"
echo "BRAKER GTF dir:         $NEW_GTF"
echo "BRAKER GFF3 dir:        $NEW_GFF3"
echo "Output base:            $OUT_BASE"
echo "  🧬 Samples seen:           ${CNT_TOTAL}"
echo "  ✅ Successfully processed:  ${CNT_OK}"
echo "  🧠 GTF/GFF from BRAKER:     ${CNT_GTF_BRAKER}"
echo "  📦 GTF from ASM dir:        ${CNT_GTF_ASM}"
echo "  ❌ Missing ASM:             ${CNT_MISS_ASM}  -> $MISS_A1"
echo "  ❌ Missing GTF:             ${CNT_MISS_GTF}  -> $MISS_G1"
echo "Files:"
echo "  • species1.txt:             $(wc -l < "$SPEC1")"
echo "  • assemblies1_clean/:       $(ls -1 "$ASM1C" 2>/dev/null | wc -l)"
echo "  • gtf1_clean/:              $(ls -1 "$GTF1C" 2>/dev/null | wc -l)"
