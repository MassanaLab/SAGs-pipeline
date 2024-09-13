#!/bin/bash

#SBATCH --time=00:12:00
#SBATCH --job-name=QBT
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=24
#SBATCH --mem=10GB
#SBATCH --output=data/logs/QBT_filter3_%A_%a.out
#SBATCH --error=data/logs/QBT_filter3_%A_%a.err
#SBATCH --array=51-74%10

SAMPLE=$(cat data/clean/Leuven_SAGs_sel_74.txt | awk "NR == ${SLURM_ARRAY_TASK_ID}") # 74

N=3

#####################################

mkdir -p ~/lustre/qbt_leuven_filter${N}/quast/

~/store/quast/metaquast.py \
 --contig-thresholds 0,1000,3000,5000 \
 -o ~/lustre/qbt_leuven_filter${N}/quast/${SAMPLE} \
 ~/lustre/filters_clean_leuven/filter${N}/${SAMPLE}_filter${N}_clean.fasta

#####################################

module load cesga/2020

mkdir -p ~/lustre/qbt_leuven_filter${N}/tiara/

~/.local/bin/tiara \
 -i ~/lustre/filters_clean_leuven/filter${N}/${SAMPLE}_filter${N}_clean.fasta \
 -o ~/lustre/qbt_leuven_filter${N}/tiara/${SAMPLE}

#####################################

module load gcc/system busco/5.3.2

mkdir -p ~/lustre/qbt_leuven_filter${N}/busco/

BUSCO_db=eukaryota_odb10

busco \
 --in ~/lustre/filters_clean_leuven/filter${N}/${SAMPLE}_filter${N}_clean.fasta \
 -o lustre/qbt_leuven_filter${N}/busco/${SAMPLE} \
 -l ${BUSCO_db} \
 -m genome \
 --cpu ${SLURM_CPUS_PER_TASK}
