#!/bin/bash

#SBATCH --time=00:05:00
#SBATCH --job-name=BUSCOx
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=12
#SBATCH --mem=8GB
#SBATCH --output=data/logs/busco_filter3_%A_%a.out
#SBATCH --error=data/logs/busco_filter3_%A_%a.err
#SBATCH --array=1-25%4

set -euo pipefail

W=coass_abril23

# ------------------- TIMER ------------------- #

JOB_START=$(date +%s)

format_time() {
  local seconds=$1
  printf "%02d:%02d:%02d" \
    $((seconds/3600)) \
    $(((seconds%3600)/60)) \
    $((seconds%60))
}

# ------------------- SAMPLE ------------------- #

SAMPLE=$(awk -v ID="${SLURM_ARRAY_TASK_ID}" 'NR == ID {print; exit}' data/clean/names_${W}.txt)

# ------------------- PATHS ------------------- #

INPUT="data/clean/braker3_${W}_post_filter3/aa/${SAMPLE}_augustus.hints.aa"

OUT_BUSCO="data/clean/busco_prot_${W}_filter3/busco"
OUT_ESS="data/clean/busco_prot_${W}_filter3_ess/busco"

mkdir -p "$OUT_BUSCO"
mkdir -p "$OUT_ESS"

BUSCO_DB_NAME="eukaryota_odb10"
BUSCO_DB_PATH="/mnt/smart/scratch/emm2/aleix/genomes/data/db/busco/${BUSCO_DB_NAME}"

# ------------------- CHECKS ------------------- #

if [[ ! -f "$INPUT" ]]; then
  echo "[ERROR] Input file not found:"
  echo "$INPUT"
  exit 1
fi

if [[ ! -d "$BUSCO_DB_PATH" ]]; then
  echo "[ERROR] BUSCO database not found:"
  echo "$BUSCO_DB_PATH"
  exit 1
fi

# ------------------- INFO ------------------- #

echo "SAMPLE    : $SAMPLE"
echo "INPUT     : $INPUT"
echo "OUT_BUSCO : $OUT_BUSCO"
echo "OUT_ESS   : $OUT_ESS"
echo "DB        : $BUSCO_DB_PATH"
echo "MODE      : proteins"
echo

# ------------------- BUSCO ------------------- #

echo "[BUSCO][$SAMPLE][filter3] Starting..."

BUSCO_START=$(date +%s)

module load busco
conda activate busco-6.0.0

busco \
  --in "$INPUT" \
  --out_path "$OUT_BUSCO" \
  -o "$SAMPLE" \
  -l "$BUSCO_DB_PATH" \
  -m proteins \
  --cpu "$SLURM_CPUS_PER_TASK"

conda deactivate || true

BUSCO_END=$(date +%s)

echo "[BUSCO][$SAMPLE][filter3] Done."
echo "[TIME][$SAMPLE][filter3] BUSCO elapsed: $(format_time $((BUSCO_END - BUSCO_START)))"

# ------------------- KEEP ONLY ESSENTIAL BUSCO SUMMARY ------------------- #

SUMMARY_FILE=$(find "$OUT_BUSCO/$SAMPLE" \
  -type f \
  -name "short_summary.specific.${BUSCO_DB_NAME}.${SAMPLE}.txt" \
  | head -n 1)

if [[ -z "$SUMMARY_FILE" ]]; then
  echo "[ERROR] BUSCO summary file not found for sample:"
  echo "$SAMPLE"
  exit 1
fi

cp "$SUMMARY_FILE" "$OUT_ESS/"

echo "[ESS][$SAMPLE] Copied summary:"
echo "$SUMMARY_FILE"
echo "to:"
echo "$OUT_ESS/"

# ------------------- FINAL TIME ------------------- #

JOB_END=$(date +%s)

echo "[TIME][$SAMPLE][filter3] Total elapsed: $(format_time $((JOB_END - JOB_START)))"
