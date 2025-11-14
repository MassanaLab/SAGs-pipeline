#!/bin/bash

#SBATCH --time=00:05:00
#SBATCH --job-name=gff_aleix_process
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=1GB
#SBATCH --output=data/logs/aleix_gff_process_coass_update_filter3_%A_%a.out
#SBATCH --error=data/logs/aleix_gff_process_coass_update_filter3_%A_%a.err
#SBATCH --array=1-2%2

W=coass_update

SAMPLE=$(cat data/clean/names_${W}.txt | awk "NR == ${SLURM_ARRAY_TASK_ID}") # 2


GFF=~/lustre/aleix_gff_process_big2_${W}_filter3/final_gff3/
EMAPP=~/lustre/eggnog_${W}_filter3_clean_skip4/
TIARA=~/lustre/qbt_${W}_filter3_ess/tiara
OUT=~/lustre/aleix_gff_${W}_process_out_filter3

mkdir -p ${OUT}


GFF_FILE=${GFF}/${SAMPLE}_filter3.gff3

EMAPPER_FILE=${EMAPP}/${SAMPLE}_eggnog.emapper.annotations_clean

TIARA_FILE=${TIARA}/${SAMPLE}

OUT_FILE=${OUT}/${SAMPLE}_gff_processed.txt


Rscript ~/scripts/full_remake/ALEIX_get_prediction_stats_v2.R ${GFF_FILE} ${EMAPPER_FILE} ${TIARA_FILE} ${OUT_FILE}
