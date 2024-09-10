#!/bin/bash

#SBATCH --time=00:01:00
#SBATCH --job-name=kaiju_process_filters
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=1GB
#SBATCH --output=data/logs/kaiju_process_filters_leuven_%A_%a.out
#SBATCH --error=data/logs/kaiju_process_filters_leuven_%A_%a.err
#SBATCH --array=51-74%10

module load cesga/system R/4.2.2


SAMPLE=$(cat data/clean/Leuven_SAGs_sel_74.txt | awk "NR == ${SLURM_ARRAY_TASK_ID}") #74


KAIJU_FILE=~/store/kaiju_Leuven_grep_C/${SAMPLE}_kaiju_faa_names_grep_C.out

PROC_GTF_FILE=~/lustre/aleix_gtf_Leuven_process_out/${SAMPLE}_gtf_processed.txt

NEW_TIARA_FILE=~/lustre/new_tiara_leuven/${SAMPLE}_new_tiara.txt

FLON_FILE=~/lustre/flon_leuven/${SAMPLE}_filter_lo_names.txt


mkdir -p ~/lustre/tables_filter_leuven

OUT_FILE=~/lustre/tables_filter_leuven/${SAMPLE}



Rscript ~/scripts/leuven/Rscripts/kaiju_process_FUNCTIONS_ARG_old_pipe.R ${KAIJU_FILE} ${PROC_GTF_FILE} ${NEW_TIARA_FILE} ${FLON_FILE} ${OUT_FILE}


