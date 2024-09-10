#!/bin/bash

#SBATCH --time=00:10:00
#SBATCH --job-name=kaiju_leuven_table1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=5GB
#SBATCH --output=data/logs/kaiju_leuven_t1_%A_%a.out
#SBATCH --error=data/logs/kaiju_leuven_t1_%A_%a.err
#SBATCH --array=51-74%10


SAMPLE=$(cat data/clean/Leuven_SAGs_sel_74.txt | awk "NR == ${SLURM_ARRAY_TASK_ID}") # 74

OUT=~/lustre/tables1_leuven

mkdir -p ${OUT}

KAIJU_FILE=~/store/kaiju_Leuven_grep_C/${SAMPLE}_kaiju_faa_names_grep_C.out

PROC_GTF_FILE=~/lustre/aleix_gtf_Leuven_process_out/${SAMPLE}_gtf_processed.txt

OUT_FILE=${OUT}/${SAMPLE}_table1.tsv


Rscript ~/scripts/leuven/Rscripts/kaiju_process_TABLE1_FUNCTIONS_ARG.R ${KAIJU_FILE} ${PROC_GTF_FILE} ${OUT_FILE}
