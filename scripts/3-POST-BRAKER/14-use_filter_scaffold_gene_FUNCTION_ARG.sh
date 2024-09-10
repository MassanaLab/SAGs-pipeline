#!/bin/bash

#SBATCH --time=00:01:00
#SBATCH --job-name=leuven_filter3_gene_link
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=1GB
#SBATCH --output=data/logs/leuven_filter3_gene_link_%A_%a.out
#SBATCH --error=data/logs/leuven_filter3_gene_link_%A_%a.err
#SBATCH --array=51-74%10

module load cesga/system R/4.2.2


SAMPLE=$(cat data/clean/Leuven_SAGs_sel_74.txt | awk "NR == ${SLURM_ARRAY_TASK_ID}") #74



PROC_GTF_FILE=~/lustre/aleix_gtf_Leuven_process_out/${SAMPLE}_gtf_processed.txt

FILTER3=~/lustre/tables_filter_leuven/${SAMPLE}_table6_filter3.tsv


OUT=lustre/filter3_scaffold_gene_link_leuven

mkdir -p ${OUT}


OUT_FILE=${OUT}/${SAMPLE}



Rscript scripts/leuven/Rscripts/filter_scaffold_gene_FUNCTION_ARG.R ${PROC_GTF_FILE} ${FILTER3} ${OUT_FILE}
