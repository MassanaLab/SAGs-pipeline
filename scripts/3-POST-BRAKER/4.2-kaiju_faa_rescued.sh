#!/bin/bash

#SBATCH --time=01:00:00
#SBATCH --job-name=kaiju_faa
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=24
#SBATCH --mem=200G
#SBATCH --output=data/logs/kaiju_faa_13_rescued_%A_%a.out
#SBATCH --error=data/logs/kaiju_faa_13_rescued_%A_%a.err
#SBATCH --array=1-13%9

SAMPLE=$(ls store/braker_LEUVEN_rescued/aa/ | awk -F "_" '{print $1"_"$2}' | awk "NR == ${SLURM_ARRAY_TASK_ID}") #61

# Fasta file

FAA=store/braker_LEUVEN_rescued/aa/${SAMPLE}_augustus.hints.aa

# Out dir and filenames

OUT_DIR=lustre/kaiju_leuven_13_rescued/${SAMPLE}

mkdir -p ${OUT_DIR}

THREADS=24

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
