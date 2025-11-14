#!/usr/bin/env bash
#set -euo pipefail

W=og_coass_update

OUT="${HOME}/lustre/qbt_${W}_ess/all_reports"

echo "[SETUP] Removing and creating ${OUT}"
rm -rf "${OUT}"
mkdir -p "${OUT}"

shopt -s nullglob

########################################################################################################################
# QUAST report
########################################################################################################################

DATA_DIR="${HOME}/lustre/qbt_${W}_ess/quast"
OUT_FILE="${OUT}/quast_report.txt"

quast_rows=( "${DATA_DIR}"/*_transposed_report.tsv )
if (( ${#quast_rows[@]} == 0 )); then
  echo "[QUAST] No transposed reports found in ${DATA_DIR}" >&2
else
  echo "[QUAST] Found ${#quast_rows[@]} reports. Building table…"
  first_quast="${quast_rows[0]}"
  HEADERS="$(head -1 "${first_quast}")"
  echo -e "Sample\t${HEADERS}" > "${OUT_FILE}"

  total=${#quast_rows[@]}
  idx=0
  for f in "${quast_rows[@]}"; do
    idx=$((idx+1))
    bn="$(basename -- "$f")"
    SAMPLE="${bn%_transposed_report.tsv}"
    printf '[QUAST] %4d/%-4d (%3d%%) %s\n' "$idx" "$total" $((idx*100/total)) "${SAMPLE}"

    REPORT="$(tail -1 "$f")"
    echo -e "${SAMPLE}\t${REPORT}" >> "${OUT_FILE}"
  done
  echo "[QUAST] Wrote ${OUT_FILE}"
fi


echo "[DONE] Reports saved in ${OUT}"
