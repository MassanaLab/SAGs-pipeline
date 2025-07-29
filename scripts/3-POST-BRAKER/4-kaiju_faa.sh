#!/bin/bash

#SBATCH --time=12:00:00
#SBATCH --job-name=kaiju
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=250G
#SBATCH --output=data/logs/kaiju_coass_juliol_%A_%a.out
#SBATCH --error=data/logs/kaiju_coass_juliol_%A_%a.err
#SBATCH --array=1-3%3

### esto en marbits suele ir mas rapido, /mnt/smart/users/gmarimon/KAIJU_coass_v5/

W=coass_juliol

SAMPLE=$(cat data/clean/names_${W}.txt | awk "NR == ${SLURM_ARRAY_TASK_ID}") # 3

# Fasta file

FAA=store/braker_${W}/aa/${SAMPLE}_augustus.hints.aa

# Out dir and filenames

OUT_DIR=lustre/kaiju_${W}/${SAMPLE}

mkdir -p ${OUT_DIR}

THREADS=8

# Load modules

module load kaiju

# Run Kaiju

kaiju \
 -t /mnt/netapp2/bio_databases/kaiju_db_nr_euk/nodes.dmp \
 -f /mnt/netapp2/bio_databases/kaiju_db_nr_euk/kaiju_db_nr_euk.fmi \
 -i ${FAA} \
 -p \
 -o ${OUT_DIR}/${SAMPLE}_kaiju_faa.out \
 -z ${THREADS}

kaiju-addTaxonNames \
 -t /mnt/netapp2/bio_databases/kaiju_db_nr_euk/nodes.dmp \
 -n /mnt/netapp2/bio_databases/kaiju_db_nr_euk/names.dmp \
 -p \
 -i ${OUT_DIR}/${SAMPLE}_kaiju_faa.out \
 -o ${OUT_DIR}/${SAMPLE}_kaiju_faa_names.out

kaiju2table \
 -t /mnt/netapp2/bio_databases/kaiju_db_nr_euk/nodes.dmp \
 -n /mnt/netapp2/bio_databases/kaiju_db_nr_euk/names.dmp \
 -r genus \
 -o ${OUT_DIR}/${SAMPLE}_kaiju_faa_summary.tsv ${OUT_DIR}/${SAMPLE}_kaiju_faa.out
