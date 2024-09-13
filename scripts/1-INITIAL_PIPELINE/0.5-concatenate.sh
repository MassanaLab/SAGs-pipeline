#!/bin/sh

#SBATCH --account=emm2
#SBATCH --job-name=concatenate
#SBATCH --cpus-per-task=2
#SBATCH --ntasks-per-node=1
#SBATCH --output=seq1/data/logs/concatenate_%A_%a.out
#SBATCH --error=seq1/data/logs/concatenate_%A_%a.err
#SBATCH --array=1-256%48

SAMPLES_FILE=seq1/data/raw/samples_file_short_seq1.txt
SAMPLE=$(cat ${SAMPLES_FILE} | awk "NR == ${SLURM_ARRAY_TASK_ID}")
DATA_DIR="seq1/data/clean/trimgalore_seq1"
OUT_DIR='seq1/data/clean/concatenate'

# concatenate

cat ${DATA_DIR}/${SAMPLE}*_1.fq.gz > ${OUT_DIR}/${SAMPLE}_1.fq.gz
cat ${DATA_DIR}/${SAMPLE}*_2.fq.gz > ${OUT_DIR}/${SAMPLE}_2.fq.gz
