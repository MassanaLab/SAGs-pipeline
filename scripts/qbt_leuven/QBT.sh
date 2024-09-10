#!/bin/bash

#SBATCH --time=0:30:00
#SBATCH --job-name=qbt
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=48
#SBATCH --mem=10GB
#SBATCH --output=data/logs/qbt_%A_%a.out
#SBATCH --error=data/logs/qbt_%A_%a.err
#SBATCH --array=51-67%2

SAMPLE=$(cat data/clean/samples_file_67.txt | awk "NR == ${SLURM_ARRAY_TASK_ID}")

#####################################

mkdir -p ~/lustre/qbt/quast/

~/store/quast/metaquast.py \
 --contig-thresholds 0,1000,3000,5000 \
 -o ~/lustre/qbt/quast/${SAMPLE} \
 ~/store/spades67/scaffolds/${SAMPLE}_scaffolds.fasta

#mkdir -p ~/lustre/qbt_essentials/quast/
#cp ~/lustre/qbt/quast/${SAMPLE}/transposed_report.tsv ~/lustre/qbt_essentials/quast/${SAMPLE}_transposed_report.tsv
#rm -r ~/lustre/qbt/quast/

#####################################

module load cesga/2020

mkdir -p ~/lustre/qbt_essentials/tiara/

~/.local/bin/tiara \
 -i ~/store/spades67/scaffolds/${SAMPLE}_scaffolds.fasta \
 -o ~/lustre/qbt_essentials/tiara/${SAMPLE}

#####################################

module load gcc/system busco/5.3.2

mkdir -p ~/lustre/qbt/busco/

BUSCO_db=eukaryota_odb10

busco \
 --in ~/store/spades67/scaffolds/${SAMPLE}_scaffolds.fasta \
 -o lustre/qbt/busco/${SAMPLE} \
 -l ${BUSCO_db} \
 -m genome \
 --cpu ${SLURM_CPUS_PER_TASK}

#mkdir -p ~/lustre/qbt_essentials/busco/
#cp ~/lustre/qbt/busco/${SAMPLE}/short_summary.specific.eukaryota_odb10.${SAMPLE}.txt ~/lustre/qbt_essentials/busco/
#rm -r ~/lustre/qbt/busco/
