#!/bin/bash

#SBATCH --time=10:00:00
#SBATCH --job-name=braker3
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=12
#SBATCH --mem=15GB
#SBATCH --output=data/logs/braker3_%A_%a.out
#SBATCH --error=data/logs/braker3_%A_%a.err
#SBATCH --array=1-2%2

# TIME should be aprox 6h

module load cesga/2020 gcc/system braker/3.0.7 seqkit/2.1.0

W=coass_update

SAG_ID=$(cat data/clean/names_${W}.txt | awk "NR == ${SLURM_ARRAY_TASK_ID}")

GENOME=~/lustre/filters_clean_${W}/filter3/${SAG_ID}_filter3_clean.fasta

PROT_DB=~/store/Eukaryota_v16.fa
OUT_DIR=~/lustre/braker3_${W}_post_filter3/${SAG_ID}

mkdir -p ${OUT_DIR}

cd $LUSTRE_SCRATCH
mkdir -p ${SAG_ID}
cd ${SAG_ID}

rm -r ~/store/config/species/${SAG_ID}
#rm -r ~/store/augustus_config/species/${SAG_ID}

## GeneMark's default contig length is >50kb
## Practically no SAG has contigs this long
## I change it here with flag `--min_contig`

CONTIGS_10K=$(seqkit seq -m 10000 ${GENOME} | grep -c '^>')
CONTIGS_5K=$(seqkit seq -m 5000 ${GENOME} | grep -c '^>')
CONTIGS_2K=$(seqkit seq -m 2000 ${GENOME} | grep -c '^>')

if (( ${CONTIGS_10K} > 100 ))
then
    MIN_CONTIG=10000
elif (( ${CONTIGS_5K} > 100 ))
then
    MIN_CONTIG=5000
elif (( ${CONTIGS_2K} > 100 ))
then
    MIN_CONTIG=2000
else
    MIN_CONTIG=1000
fi

## BRAKER prediction

echo -e "# Predicting SAG ${SAG_ID}\n"
echo -e "# Working directory: ${PWD}\n"
echo -e "# Min contig size used: ${MIN_CONTIG}"

braker.pl \
  --species=${SAG_ID} \
  --genome=${GENOME} \
  --prot_seq=${PROT_DB} \
  --min_contig=${MIN_CONTIG} \
  --threads=${SLURM_CPUS_PER_TASK} \
  --gff3 \
  --AUGUSTUS_CONFIG_PATH=/home/csic/eyg/gmf/store/config/ \
  --AUGUSTUS_BIN_PATH=/opt/cesga/2020/software/Compiler/gcc/system/augustus/3.4.0/bin/

#cp ${LUSTRE_SCRATCH}/${SAG_ID}/braker/* ${OUT_DIR}

# --- Copy only the files you want ---
SRC_DIR="${LUSTRE_SCRATCH}/${SAG_ID}/braker"
FILES_TO_COPY=( braker.aa braker.codingseq braker.gff3 braker.gtf braker.log )

echo "# Collecting outputs from: ${SRC_DIR}"
for f in "${FILES_TO_COPY[@]}"; do
  src="${SRC_DIR}/${f}"
  [[ -s "${src}" ]] && cp -v "${src}" "${OUT_DIR}/" || echo "WARN: missing or empty: ${src}" >&2
done

# SIEMPRE traer los logs crudos para debug
for f in GeneMark-EP.stdout errors/GeneMark-EP.stderr what-to-cite.txt prothint.gff genemark_hintsfile.gff; do
  [[ -s "${SRC_DIR}/${f}" ]] && {
    mkdir -p "${OUT_DIR}/errors"
    cp -v "${SRC_DIR}/${f}" "${OUT_DIR}/${f}"
  }
done

# !!!!!!!!!!!!!! EN PROXIMOS BRAKER COPIAR TAMBIEN LA VARIABLE GENOME

# (optional) also copy these if you want
# for f in genome_header.map hintsfile.gff prothint.gff what-to-cite.txt; do
#   [[ -s "${SRC_DIR}/${f}" ]] && cp -v "${SRC_DIR}/${f}" "${OUT_DIR}/" || true
# done

echo "# Done. Output in: ${OUT_DIR}"
