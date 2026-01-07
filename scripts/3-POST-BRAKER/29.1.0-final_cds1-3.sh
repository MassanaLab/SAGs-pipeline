#!/usr/bin/env bash
# Collect *_longisoforms_150plus_cds.fasta into final_cds/ with names:
#   <sample>_filter1_genes.cds  (from results_f1_50aa)
#   <sample>_filter3_genes.cds  (from results_f3_50aa)
#
# Usage:
#   bash copy_final_cds_150plus.sh [BASE1] [BASE3]
# Defaults:
#   BASE1=lustre/aleix_gff_process_big2
#   BASE3=lustre/aleix_gff_process_big2_filter3
#
# Env options:
#   RESET_FINAL=1   # wipe final_cds/ before copying
#   OVERWRITE=1     # overwrite existing destination files (else skip)
#   FALLBACK=1      # if 150plus missing, pick numerically largest *plus

set -euo pipefail
export LC_ALL=C
shopt -s nullglob

W=coass_ICM0002

BASE1="${1:-lustre/aleix_gff_process_big2_${W}}"
BASE3="${2:-lustre/aleix_gff_process_big2_${W}_filter3}"

# choose copy behavior
_do_cp() {
  local src="$1" dst="$2"
  if [[ "${OVERWRITE:-0}" == "1" ]]; then
    cp -f -- "$src" "$dst"
  else
    cp -n -- "$src" "$dst"
  fi
}

_pick_src_cds() {
  # args: dir sample  -> echoes chosen source path or nothing
  local dir="$1" sample="$2"
  local p150="${dir}/${sample}_longisoforms_150plus_cds.fasta"
  if [[ -f "$p150" ]]; then
    echo "$p150"; return 0
  fi
  if [[ "${FALLBACK:-0}" == "1" ]]; then
    local best_num=-1 best_path=""
    local f n
    for f in "${dir}/${sample}"_longisoforms_*plus_cds.fasta; do
      [[ -f "$f" ]] || continue
      n="${f##*_longisoforms_}"; n="${n%plus_cds.fasta}"
      [[ "$n" =~ ^[0-9]+$ ]] || continue
      if (( 10#$n > best_num )); then best_num=$((10#$n)); best_path="$f"; fi
    done
    [[ -n "$best_path" ]] && echo "$best_path"
  fi
}

_copy_set() {
  local base="$1" filt="$2"               # filt = 1 or 3
  local src_root="${base}/results_f${filt}_50aa"
  local dest="${base}/final_cds"

  if [[ ! -d "$src_root" ]]; then
    echo "⚠️  Skip: source dir not found: $src_root"
    return 0
  fi

  # optional clean slate
  if [[ "${RESET_FINAL:-0}" == "1" && -d "$dest" ]]; then
    echo "🧹 Resetting $dest"
    rm -rf -- "$dest"
  fi
  mkdir -p "$dest"

  local copied=0 skipped=0 missing=0
  local d sample src dst

  for d in "${src_root}"/*; do
    [[ -d "$d" ]] || continue
    sample="$(basename "$d")"

    src="$(_pick_src_cds "$d" "$sample" || true)"
    if [[ -z "$src" ]]; then
      ((missing++)) || true
      continue
    fi

    dst="${dest}/${sample}_filter${filt}_genes.cds"
    if [[ -e "$dst" && "${OVERWRITE:-0}" != "1" ]]; then
      ((skipped++)) || true
      continue
    fi

    _do_cp "$src" "$dst"
    ((copied++)) || true
  done

  echo "✅ filter${filt}: copied=${copied}  skipped=${skipped}  missing=${missing}  → ${dest}"
}

_copy_set "$BASE1" 1
_copy_set "$BASE3" 3
