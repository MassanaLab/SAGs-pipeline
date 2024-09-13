#!/bin/bash

#SBATCH --time=05:00:00
#SBATCH --job-name=eggnog
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=10GB
#SBATCH --output=data/logs/eggnog_leuven_%A_%a.out
#SBATCH --error=data/logs/eggnog_leuven_%A_%a.err
#SBATCH --array=101-150%2

module load cesga/2020  gcccore/system eggnog-mapper/2.1.10


AA=~/lustre/braker_LEUVEN/aa

SAMPLE=$(ls lustre/braker_LEUVEN/aa/ | awk -F "_" '{print $1"_"$2}' | awk "NR == ${SLURM_ARRAY_TASK_ID}") # 61

DATA_OUT=~/lustre/eggnog_LEUVEN/${SAMPLE}

mkdir -p ${DATA_OUT}

cd ${DATA_OUT}

#module load eggnog-mapper
#source activate eggnog-mapper

emapper.py -i ${AA}/${SAMPLE}_augustus.hints.aa -o ${SAMPLE}_eggnog --cpu 8
