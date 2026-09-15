#!/bin/bash
#SBATCH --account=emm2
#SBATCH --job-name=mtags
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=48
#SBATCH --output=data/logs/mtags_%A.out  # Include job ID (%A) and array task ID (%a)
#SBATCH --error=data/logs/mtags_%A.err   # Include job ID (%A) and array task ID (%a)


module load snakemake
module load vsearch
module load blast
module load python
module load seqkit

module load R/4.2.2

#conda activate mtags_snakemake

#ls /mnt/smart/scratch/emm2/MASSANARAM_11/ | awk -F "_" '{print $1"_"$2"_"$3"_"$4}' | uniq > samples.txt

snakemake \
  --cores "${SLURM_CPUS_PER_TASK}" \
  --rerun-incomplete \
  --printshellcmds
