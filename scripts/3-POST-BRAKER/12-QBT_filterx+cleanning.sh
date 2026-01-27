#!/bin/bash

#SBATCH --time=01:00:00
#SBATCH --job-name=QBTx
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=12
#SBATCH --mem=8GB
#SBATCH --output=data/logs/qbt_filter3_%A_%a.out
#SBATCH --error=data/logs/qbt_filter3_%A_%a.err
#SBATCH --array=1-2%2

W=coass_update #!!!!

SAMPLE=$(cat data/clean/names_${W}.txt | awk "NR == ${SLURM_ARRAY_TASK_ID}") # 2 #!!!!

N=3 #!!!! put 1 or 2 or 3

INPUT=lustre/filters_clean_${W}/filter${N}/${SAMPLE}_filter${N}_clean.fasta #!!!!


#####################################

OUT_QUAST=lustre/qbt_${W}_filter${N}/quast

mkdir -p ${OUT_QUAST}

~/store/quast/metaquast.py \
 --contig-thresholds 0,1000,3000,5000 \
 -o ~/${OUT_QUAST}/${SAMPLE} \
 ~/${INPUT}

#####################################

module load cesga/2020

OUT_TIARA=lustre/qbt_${W}_filter${N}/tiara

mkdir -p ${OUT_TIARA}

~/.local/bin/tiara \
 -i ~/${INPUT} \
 -o ~/${OUT_TIARA}/${SAMPLE}

#####################################

module load gcc/system busco/5.3.2

OUT_BUSCO=lustre/qbt_${W}_filter${N}/busco

mkdir -p ~/${OUT_BUSCO}

BUSCO_db=eukaryota_odb10

busco \
 --in ~/${INPUT} \
 -o ${OUT_BUSCO}/${SAMPLE} \
 -l ${BUSCO_db} \
 -m genome \
 --cpu ${SLURM_CPUS_PER_TASK}


##################################################
################## CLEANNING #####################
##################################################

#####################################
# Cleaning (per-sample) — append results into qbt_${W}_ess
#####################################

OUT_ESS=lustre/qbt_${W}_filter${N}_ess
echo "[CLEAN][$SAMPLE] Creating essentials dirs at ~/${OUT_ESS}/{quast,busco,tiara}"
mkdir -p ~/${OUT_ESS}/quast ~/${OUT_ESS}/busco ~/${OUT_ESS}/tiara


# Copy TIARA output for this sample (main files + logs)
tiara_dir="${HOME}/${OUT_TIARA}"
dest_dir="${HOME}/${OUT_ESS}/tiara"
mkdir -p "${dest_dir}"

shopt -s nullglob
tiara_matches=( "${tiara_dir}/${SAMPLE}"* "${tiara_dir}/log_${SAMPLE}"* )

if (( ${#tiara_matches[@]} )); then
  echo "[CLEAN][$SAMPLE] TIARA: copying ${#tiara_matches[@]} files -> ${dest_dir}"
  cp "${tiara_matches[@]}" "${dest_dir}/"
  # Print the filenames copied (basename only)
  echo "[CLEAN][$SAMPLE] TIARA: copied -> $(printf '%s ' "${tiara_matches[@]##*/}")"
  echo "[CLEAN][$SAMPLE] TIARA: done"
else
  echo "[CLEAN][$SAMPLE] TIARA: nothing found for patterns '${SAMPLE}*' or 'log_${SAMPLE}*' in ${tiara_dir}"
fi
shopt -u nullglob




# Copy QUAST transposed report for this sample
if [[ -f ~/${OUT_QUAST}/${SAMPLE}/transposed_report.tsv ]]; then
  echo "[CLEAN][$SAMPLE] QUAST: copying transposed_report.tsv -> ~/${OUT_ESS}/quast/${SAMPLE}_transposed_report.tsv"
  cp ~/${OUT_QUAST}/${SAMPLE}/transposed_report.tsv \
     ~/${OUT_ESS}/quast/${SAMPLE}_transposed_report.tsv
  echo "[CLEAN][$SAMPLE] QUAST: done"
else
  echo "[CLEAN][$SAMPLE] QUAST: missing (~/${OUT_QUAST}/${SAMPLE}/transposed_report.tsv)"
fi



# Copy BUSCO short summary for this sample
BUSCO_SUM=~/${OUT_BUSCO}/${SAMPLE}/short_summary.specific.${BUSCO_db}.${SAMPLE}.txt
if [[ -f "${BUSCO_SUM}" ]]; then
  echo "[CLEAN][$SAMPLE] BUSCO: copying ${BUSCO_SUM} -> ~/${OUT_ESS}/busco/"
  cp "${BUSCO_SUM}" ~/${OUT_ESS}/busco/
  echo "[CLEAN][$SAMPLE] BUSCO: done"
else
  echo "[CLEAN][$SAMPLE] BUSCO: missing (${BUSCO_SUM})"
fi

echo "[CLEAN][$SAMPLE] Completed."
