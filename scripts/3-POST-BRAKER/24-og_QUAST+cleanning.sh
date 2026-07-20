#!/bin/bash

#SBATCH --time=00:05:00
#SBATCH --job-name=QUAST
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=2GB
#SBATCH --output=data/logs/quast_og_coass_update_%A_%a.out
#SBATCH --error=data/logs/quast_og_coass_update_%A_%a.err
#SBATCH --array=1-2%2

W=coass_update #!!!!

SAMPLE=$(cat data/clean/names_${W}.txt | awk "NR == ${SLURM_ARRAY_TASK_ID}") # 2 #!!!!

INPUT=lustre/spades_${W}/${SAMPLE}_scaffolds.fasta #!!!!

#N=1000 #!!!!

#####################################

OUT_QUAST=lustre/qbt_og_${W}/quast

mkdir -p ${OUT_QUAST}

~/store/quast/metaquast.py \
 --contig-thresholds 0,1000,3000,5000 \
 -o ~/${OUT_QUAST}/${SAMPLE} \
 ~/${INPUT}


#####################################
# Cleaning (per-sample) — append results into qbt_og_${W}_ess
# This avoids rm -r and race conditions across array tasks.
#####################################

OUT_ESS=lustre/qbt_og_${W}_ess
echo "[CLEAN][$SAMPLE] Creating essentials dirs at ~/${OUT_ESS}/{quast,busco,tiara}"
mkdir -p ~/${OUT_ESS}/quast


# Copy QUAST transposed report for this sample
if [[ -f ~/${OUT_QUAST}/${SAMPLE}/transposed_report.tsv ]]; then
  echo "[CLEAN][$SAMPLE] QUAST: copying transposed_report.tsv -> ~/${OUT_ESS}/quast/${SAMPLE}_transposed_report.tsv"
  cp ~/${OUT_QUAST}/${SAMPLE}/transposed_report.tsv \
     ~/${OUT_ESS}/quast/${SAMPLE}_transposed_report.tsv
  echo "[CLEAN][$SAMPLE] QUAST: done"
else
  echo "[CLEAN][$SAMPLE] QUAST: missing (~/${OUT_QUAST}/${SAMPLE}/transposed_report.tsv)"
fi
