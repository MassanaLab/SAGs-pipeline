#!/usr/bin/env bash
set -euo pipefail

W0=coass_abril23

W=busco_prot_${W0}_filter3

BASE="data/clean/${W}_ess"
DATA_DIR="${BASE}/busco"
OUT="${BASE}/all_reports"
OUT_FILE="${OUT}/busco_report.txt"

echo "[SETUP] Removing and creating ${OUT}"
rm -rf "${OUT}"
mkdir -p "${OUT}"

shopt -s nullglob

################################################################################
# BUSCO report
################################################################################

busco_files=( "${DATA_DIR}"/short_summary.specific.eukaryota_odb10.*.txt )

if (( ${#busco_files[@]} == 0 )); then
  echo "[BUSCO] No short summaries found in ${DATA_DIR}" >&2
  exit 1
fi

echo "[BUSCO] Found ${#busco_files[@]} files. Building headers and rows…"

first_busco="${busco_files[0]}"

HEADERS="$(
  grep -v '^#' "${first_busco}" \
    | sed '/^$/d' \
    | grep -v '%' \
    | perl -pe 's/.*\d+\s+//' \
    | tr '\n' '\t'
)"

echo -e "Sample\t${HEADERS}" > "${OUT_FILE}"

total=${#busco_files[@]}
idx=0

for f in "${busco_files[@]}"; do
  idx=$((idx+1))

  SAMPLE="${f##*.eukaryota_odb10.}"
  SAMPLE="${SAMPLE%.txt}"

  printf '[BUSCO] %4d/%-4d (%3d%%) %s\n' "$idx" "$total" $((idx*100/total)) "${SAMPLE}"

  REPORT="$(
    grep -v '^#' "$f" \
      | perl -pe 's/^\n//' \
      | awk '{print $1}' \
      | tr '\n' '\t'
  )"

  echo -e "${SAMPLE}\t${REPORT}" >> "${OUT_FILE}"
done

echo "[BUSCO] Wrote ${OUT_FILE}"
