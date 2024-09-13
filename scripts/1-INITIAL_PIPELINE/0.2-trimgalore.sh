#!/bin/sh

#SBATCH --account=emm2
#SBATCH --job-name=trimgalore
#SBATCH --cpus-per-task=6
#SBATCH --ntasks-per-node=1
#SBATCH --output=seq1/data/logs/trimgalore_seq1%A_%a.out
#SBATCH --error=seq1/data/logs/trimgalore_seq1%A_%a.err
#SBATCH --array=1-256%24 #put 2 times the number of sags you have

# Load module

module load cutadapt

source activate cutadapt

module load fastqc


# Variables

DATA_PATH="seq1/data/raw/"
OUT_DIR="seq1/data/clean/trimgalore_seq1"
SAMPLES_FILE=seq1/data/raw/samples_file_seq1.txt # file with sample names to process, one per line, with no pair (forward/reverse) info
SAMPLE=$(cat ${SAMPLES_FILE} | awk "NR == ${SLURM_ARRAY_TASK_ID}")
THREADS=6


# Run trimgalore


/mnt/lustre/repos/bio/projects/MassanaLab/Programs/TrimGalore-0.6.6/trim_galore  \
  --paired ${DATA_PATH}/${SAMPLE}.R1.fastq.gz ${DATA_PATH}/${SAMPLE}.R2.fastq.gz -o ${OUT_DIR} \
  --length 75
