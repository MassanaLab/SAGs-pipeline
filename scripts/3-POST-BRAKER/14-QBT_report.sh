#!/usr/bin/env bash

N=$1

W=coass_last

OUT="${HOME}/lustre/qbt_${W}_filter${N}_ess/all_reports${N}"

echo "[SETUP] Removing and creating ${OUT}"
rm -rf "${OUT}"
mkdir -p "${OUT}"

shopt -s nullglob

########################################
# BUSCO report
########################################
DATA_DIR="${HOME}/lustre/qbt_${W}_filter${N}_ess/busco"
OUT_FILE="${OUT}/busco_report.txt"

busco_files=( "${DATA_DIR}"/short_summary.specific.eukaryota_odb10.*.txt )
if (( ${#busco_files[@]} == 0 )); then
  echo "[BUSCO] No short summaries found in ${DATA_DIR}" >&2
else
  echo "[BUSCO] Found ${#busco_files[@]} files. Building headers and rows…"
  first_busco="${busco_files[0]}"
  HEADERS="$(grep -v '^#' "${first_busco}" | sed '/^$/d' | grep -v '%' | perl -pe 's/.*\d+\s+//' | tr '\n' '\t')"
  echo -e "Sample\t${HEADERS}" > "${OUT_FILE}"

  total=${#busco_files[@]}
  idx=0
  for f in "${busco_files[@]}"; do
    idx=$((idx+1))
    SAMPLE="${f##*.eukaryota_odb10.}"
    SAMPLE="${SAMPLE%.txt}"
    printf '[BUSCO] %4d/%-4d (%3d%%) %s\n' "$idx" "$total" $((idx*100/total)) "${SAMPLE}"

    REPORT="$(grep -v '^#' "$f" | perl -pe 's/^\n//' | awk '{print $1}' | tr '\n' '\t')"
    echo -e "${SAMPLE}\t${REPORT}" >> "${OUT_FILE}"
  done
  echo "[BUSCO] Wrote ${OUT_FILE}"
fi


########################################
# TIARA report (uses log_* files)
########################################
DATA_DIR="${HOME}/lustre/qbt_${W}_filter${N}_ess/tiara"
OUT_FILE="${OUT}/tiara_report.txt"

# Choose how many tabs between Sample and the text:
SEP=$'\t'          # one tab (recommended)
# SEP=$'\t\t'      # uncomment for two tabs

tiara_logs=( "${DATA_DIR}"/log_* )
if (( ${#tiara_logs[@]} == 0 )); then
  echo "[TIARA] No logs found in ${DATA_DIR}" >&2
else
  : > "${OUT_FILE}"
  echo "[TIARA] Found ${#tiara_logs[@]} log files. Parsing categories…"

  total=${#tiara_logs[@]}
  idx=0
  for logf in "${tiara_logs[@]}"; do
    idx=$((idx+1))
    base="$(basename -- "$logf")"
    SAMPLE="${base#log_}"

    # Drop ONLY the final extension, keep internal dots in the sample
    case "$SAMPLE" in
      *.txt.gz) SAMPLE="${SAMPLE%.txt.gz}";;
      *.log.gz) SAMPLE="${SAMPLE%.log.gz}";;
      *.txt)    SAMPLE="${SAMPLE%.txt}";;
      *.log)    SAMPLE="${SAMPLE%.log}";;
    esac

    printf '[TIARA] %4d/%-4d (%3d%%) %s\n' "$idx" "$total" $((idx*100/total)) "${SAMPLE}"

    # Trim leading whitespace from the metric line and print with exactly SEP as delimiter.
    # Filter only desired categories.
    awk -v s="$SAMPLE" -v sep="$SEP" '
      BEGIN { OFS=sep }
      /^[[:space:]]*(archaea|bacteria|eukarya|organelle|unknown|prokarya|mitochondrion|plastid)[[:space:]]*:/ {
        gsub(/^[ \t]+/, "", $0);   # remove leading spaces/tabs
        print s, $0
      }
    ' "$logf" >> "${OUT_FILE}"
  done
  echo "[TIARA] Wrote ${OUT_FILE}"
fi



########################################
# QUAST report
########################################
DATA_DIR="${HOME}/lustre/qbt_${W}_filter${N}_ess/quast"
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

shopt -u nullglob

echo "[DONE] Reports saved in ${OUT}"
