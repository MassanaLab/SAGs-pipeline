#!/bin/bash

#SBATCH --time=00:30:00
#SBATCH --job-name=qbt
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=18
#SBATCH --mem=5GB
#SBATCH --output=data/logs/qbt_david_52_%A_%a.out
#SBATCH --error=data/logs/qbt_david_52_%A_%a.err
#SBATCH --array=51-52%2

SAMPLE=$(cat store/BL_SAGS_052018/List | awk "NR == ${SLURM_ARRAY_TASK_ID}") # 52

#####################################

mkdir -p ~/lustre/qbt_david_52/quast/

~/store/quast/metaquast.py \
 --contig-thresholds 0,1000,3000,5000 \
 -o ~/lustre/qbt_david_52/quast/${SAMPLE} \
 ~/store/BL_SAGS_052018/${SAMPLE}/*_assembly.fasta

#####################################

module load cesga/2020

mkdir -p ~/lustre/qbt_david_52/tiara/

~/.local/bin/tiara \
 -i ~/store/BL_SAGS_052018/${SAMPLE}/*_assembly.fasta \
 -o ~/lustre/qbt_david_52/tiara/${SAMPLE}

#####################################

module load gcc/system busco/5.3.2

mkdir -p ~/lustre/qbt_david_52/busco/

BUSCO_db=eukaryota_odb10

busco \
 --in ~/store/BL_SAGS_052018/${SAMPLE}/*_assembly.fasta \
 -o lustre/qbt_david_52/busco/${SAMPLE} \
 -l ${BUSCO_db} \
 -m genome \
 --cpu ${SLURM_CPUS_PER_TASK}
