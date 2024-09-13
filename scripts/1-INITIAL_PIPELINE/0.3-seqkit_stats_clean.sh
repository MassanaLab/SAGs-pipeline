#!/bin/sh

#SBATCH --account=emm2
#SBATCH --job-name=seqkit
#SBATCH --cpus-per-task=24
#SBATCH --ntasks-per-node=1
#SBATCH --output=seq1/data/logs/seqkit_clean_%J.out
#SBATCH --error=seq1/data/logs/seqkit_clean_%J.err

DATA=seq1/data/clean/trimgalore_seq1/*.gz # change to your filepath
THREADS=24
OUT=seq1/data/clean/seqkit_clean_seq1.txt

module load seqkit

seqkit stats \
  ${DATA} \
  -j ${THREADS} > ${OUT}
