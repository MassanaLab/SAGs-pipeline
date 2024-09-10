#!/bin/bash

#SBATCH --time=00:02:00
#SBATCH --job-name=gtf_leuven_process
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=1GB
#SBATCH --output=data/logs/aleix_gtf_LEUVEN_rescued_%A_%a.out
#SBATCH --error=data/logs/aleix_gtf_LEUVEN_rescued_%A_%a.err
#SBATCH --array=1-13%10


SAMPLE=$(cat data/clean/Leuven_13_rescued.txt | awk "NR == ${SLURM_ARRAY_TASK_ID}")

GTF=~/store/braker_LEUVEN_rescued/gtf
EMAPP=~/store/eggnog_LEUVEN_clean_skip4/
TIARA=~/store/tiara_leuven_74
OUT=~/lustre/aleix_gtf_Leuven_process_out

mkdir -p ${OUT}


GTF_FILE=${GTF}/${SAMPLE}_augustus.hints.gtf

EMAPPER_FILE=${EMAPP}/${SAMPLE}_eggnog.emapper.annotations_clean

TIARA_FILE=${TIARA}/${SAMPLE}

OUT_FILE=${OUT}/${SAMPLE}_gtf_processed.txt


Rscript ~/scripts/leuven/Rscripts/ALEIX_get_prediction_stats.R ${GTF_FILE} ${EMAPPER_FILE} ${TIARA_FILE} ${OUT_FILE}
