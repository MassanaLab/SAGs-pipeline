#!/bin/bash

#SBATCH --time=00:05:00
#SBATCH --job-name=gtf_aleix_process
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=1GB
#SBATCH --output=data/logs/aleix_gtf_coass_juliol_%A_%a.out
#SBATCH --error=data/logs/aleix_gtf_coass_juliol_%A_%a.err
#SBATCH --array=1-3%3

W=coass_juliol

SAMPLE=$(cat data/clean/names_${W}.txt | awk "NR == ${SLURM_ARRAY_TASK_ID}") # 3

GTF=~/store/braker_${W}/gtf/
EMAPP=~/lustre/eggnog_${W}_clean_skip4/
TIARA=~/lustre/qbt_coassembly_filter1000_juliol/tiara
OUT=~/lustre/aleix_gtf_${W}_process_out

mkdir -p ${OUT}


GTF_FILE=${GTF}/${SAMPLE}_augustus.hints.gtf

EMAPPER_FILE=${EMAPP}/${SAMPLE}_eggnog.emapper.annotations_clean

TIARA_FILE=${TIARA}/${SAMPLE}

OUT_FILE=${OUT}/${SAMPLE}_gtf_processed.txt


Rscript ~/scripts/leuven/Rscripts/ALEIX_get_prediction_stats_v2.R ${GTF_FILE} ${EMAPPER_FILE} ${TIARA_FILE} ${OUT_FILE}
