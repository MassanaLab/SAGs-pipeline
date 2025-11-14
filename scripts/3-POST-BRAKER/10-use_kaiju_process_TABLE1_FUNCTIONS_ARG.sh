#!/bin/bash

#SBATCH --time=00:02:00
#SBATCH --job-name=kaiju_coass_juliol_table1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=2GB
#SBATCH --output=data/logs/kaiju_coass_juliol_t1_%A_%a.out
#SBATCH --error=data/logs/kaiju_coass_juliol_t1_%A_%a.err
#SBATCH --array=1-3%3

module load cesga/system R/4.2.2

W=coass_juliol

SAMPLE=$(cat data/clean/names_${W}.txt | awk "NR == ${SLURM_ARRAY_TASK_ID}") # 3

KAIJU_FILE=~/lustre/kaiju_${W}_grep_C/${SAMPLE}_kaiju_faa_names_grep_C.out

PROC_GTF_FILE=~/lustre/aleix_gff_${W}_process_out/${SAMPLE}_gff_processed.txt

NEW_TIARA_FILE=~/lustre/new_tiara_${W}/${SAMPLE}_new_tiara.txt

FLON_FILE=~/lustre/flon_${W}/${SAMPLE}_filter_lo_names.txt


# ¡¡CAREFUL!!, esto de abajo dejarlo como está, a R le gusta así, no hacer variable ${OUT} ni nada

mkdir -p ~/lustre/tables_filter_${W}

OUT_FILE=~/lustre/tables_filter_${W}/${SAMPLE}


Rscript ~/scripts/leuven/Rscripts/kaiju_process_FUNCTIONS_ARG_old_pipe.R ${KAIJU_FILE} ${PROC_GTF_FILE} ${NEW_TIARA_FILE} ${FLON_FILE} ${OUT_FILE}
