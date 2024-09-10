#!/bin/bash

#SBATCH --time=00:02:00
#SBATCH --job-name=gtf_leuven_process
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=1GB
#SBATCH --output=data/logs/aleix_gtf_LEUVEN_%A_%a.out
#SBATCH --error=data/logs/aleix_gtf_LEUVEN_%A_%a.err
#SBATCH --array=51-61%3


SAMPLE=$(ls lustre/braker_LEUVEN/gtf/ | awk -F "_" '{print $1"_"$2}' | awk "NR == ${SLURM_ARRAY_TASK_ID}") #61

GTF=~/lustre/braker_LEUVEN/gtf
EMAPP=~/lustre/eggnog_LEUVEN_clean_skip4
TIARA=~/store/tiara_61
OUT=~/lustre/aleix_gtf_Leuven_process_out

mkdir -p ${OUT}


GTF_FILE=${GTF}/${SAMPLE}_augustus.hints.gtf

EMAPPER_FILE=${EMAPP}/${SAMPLE}_eggnog.emapper.annotations_clean

TIARA_FILE=${TIARA}/${SAMPLE}

OUT_FILE=${OUT}/${SAMPLE}_gtf_processed.txt


Rscript ~/scripts/leuven/Rscripts/ALEIX_get_prediction_stats.R ${GTF_FILE} ${EMAPPER_FILE} ${TIARA_FILE} ${OUT_FILE}
