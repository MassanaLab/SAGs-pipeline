#!/bin/bash

#SBATCH --time=0:10:00
#SBATCH --job-name=tiara
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=12
#SBATCH --mem=5GB
#SBATCH --output=data/logs/tiara_leuven_%A_%a.out
#SBATCH --error=data/logs/tiara_leuven_%A_%a.err
#SBATCH --array=51-74%10

SAMPLE=$(cat data/clean/Leuven_SAGs_sel_74.txt | awk "NR == ${SLURM_ARRAY_TASK_ID}") # 74

#####################################

module load cesga/2020

mkdir -p ~/store/tiara_leuven_74/

~/.local/bin/tiara \
 -i ~/store/Leuven_spades_103/scaffolds/${SAMPLE}_scaffolds.fasta \
 -o ~/store/tiara_leuven_74/${SAMPLE}

