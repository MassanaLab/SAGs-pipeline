#!/bin/bash

#SBATCH --time=00:01:00
#SBATCH --job-name=filters_gene_link
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=1GB
#SBATCH --output=data/logs/filters_gene_link_%A_%a.out
#SBATCH --error=data/logs/filters_gene_link_%A_%a.err
#SBATCH --array=1-8%8

module load cesga/system R/4.2.2

W=david_8_coass

SAMPLE=$(cat data/clean/${W}.txt | awk "NR == ${SLURM_ARRAY_TASK_ID}") # 8

PROC_GTF_FILE=~/lustre/aleix_gtf_${W}_process_out/${SAMPLE}_gtf_processed.txt


FILTER1=~/lustre/tables_filter_${W}/${SAMPLE}_table6_filter1.tsv

FILTER2=~/lustre/tables_filter_${W}/${SAMPLE}_table6_filter2.tsv


OUT_FILE1=~/lustre/filter1_scaffold_gene_link_${W}/${SAMPLE}

OUT_FILE2=~/lustre/filter2_scaffold_gene_link_${W}/${SAMPLE}

mkdir -p ${OUT_FILE1}
mkdir -p ${OUT_FILE2}


Rscript scripts/og+3filters_gene_count/filter1_scaffold_gene_FUNCTION_ARG.R ${PROC_GTF_FILE} ${FILTER1} ${OUT_FILE1}

Rscript scripts/og+3filters_gene_count/filter2_scaffold_gene_FUNCTION_ARG.R ${PROC_GTF_FILE} ${FILTER2} ${OUT_FILE2}


# NS QUE ES ESTO LO IGNORO !!!!!!!! HAY QUE HACER FILTEEEEEEEEEEEEEEEEEEEEER 3  que tambien hay duplicados !!!!!!!!!! ->>>> NS QUE ES ESTO LO IGNORO
