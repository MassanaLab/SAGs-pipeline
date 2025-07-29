#!/bin/bash

#SBATCH --time=00:05:00
#SBATCH --job-name=kaiju_coass_juliol_table1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=2GB
#SBATCH --output=data/logs/kaiju_coass_juliol_t1_%A_%a.out
#SBATCH --error=data/logs/kaiju_coass_juliol_t1_%A_%a.err
#SBATCH --array=1-3%3

W=coass_juliol


SAMPLE=$(cat data/clean/names_${W}.txt | awk "NR == ${SLURM_ARRAY_TASK_ID}") # 3

OUT=~/lustre/tables1_${W}

mkdir -p ${OUT}

KAIJU_FILE=~/lustre/kaiju_${W}_grep_C/${SAMPLE}_kaiju_faa_names_grep_C.out

PROC_GTF_FILE=~/lustre/aleix_gtf_${W}_process_out/${SAMPLE}_gtf_processed.txt

OUT_FILE=${OUT}/${SAMPLE}_table1.tsv


Rscript ~/scripts/leuven/Rscripts/kaiju_process_TABLE1_FUNCTIONS_ARG.R ${KAIJU_FILE} ${PROC_GTF_FILE} ${OUT_FILE}
