!/bin/bash

#SBATCH --time=05:00:00
#SBATCH --job-name=eggnog
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=10GB
#SBATCH --output=data/logs/eggnog_coass_update__f3_%A_%a.out
#SBATCH --error=data/logs/eggnog_coass_update_f3_%A_%a.err
#SBATCH --array=1-2%2

module load cesga/2020  gcccore/system eggnog-mapper/2.1.10

W=coass_update

AA=~/lustre/aleix_gff_process_big2_${W}_filter3/final_faa

SAMPLE=$(cat data/clean/names_${W}.txt | awk "NR == ${SLURM_ARRAY_TASK_ID}") # 2

DATA_OUT=~/lustre/eggnog_${W}_filter3/${SAMPLE}

mkdir -p ${DATA_OUT}

cd ${DATA_OUT}


emapper.py -i ${AA}/${SAMPLE}_filter3_genes.faa -o ${SAMPLE}_eggnog --cpu 8

# ---------------------- skip 4 ----------------------
# Clean annotations: skip first 4 header lines and remove '#'
OUT=~/lustre/eggnog_${W}_filter3_clean_skip4
mkdir -p "${OUT}"

E=~/lustre/eggnog_${W}_filter3
in_file="${E}/${SAMPLE}/${SAMPLE}_eggnog.emapper.annotations"
out_file="${OUT}/${SAMPLE}_eggnog.emapper.annotations_clean"

if [[ -f "$in_file" ]]; then
  tail -n +5 "$in_file" | sed 's/#//g' > "$out_file"
  echo "Cleaned: $out_file"
else
  echo "Skip cleaning (missing: $in_file)"
fi
# ---------------------------------------------------------------
