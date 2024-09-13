#!/bin/sh

#SBATCH --account=emm2
#SBATCH --job-name=extraction
#SBATCH --cpus-per-task=4
#SBATCH --ntasks-per-node=1
#SBATCH --output=seq1/data/logs/extract_BLAST_ALEIX_%A_%a.out
#SBATCH --error=seq1/data/logs/extract_BLAST_ALEIX_%A_%a.err
#SBATCH --array=1-128%48 #CUIDADO EL NUMERO ESTE
#SBATCH --exclude=c[01-10]

#================================================

##########VARIABLES#########

# Load modules and apps

module load blast/2.7.1
module load seqkit

# Path to files

DATA_DIR=seq1/data/clean/concatenated/

FASTA_OUT_DIR=seq1/data/mtags
BLAST_OUT_DIR=seq1/data/blast

SAMPLE=$(ls ${DATA_DIR} | grep '^GC' | cut -f1,2 -d'_' | sort -u | awk "NR == ${SLURM_ARRAY_TASK_ID}")

DB_BLAST="../04-Databases/eukaryotesV4_extraction/Mitags_V4_ref_v15_BLAST"

# Parameters

NUM_THREADS=4

###########SCRIPT###########

seqs_original=$(echo $(zcat ${DATA_DIR}/${SAMPLE}*.fq*.gz | wc -l) / 4 | bc) # count total seqs in the clean fastq file

date
echo '# Convert to fasta'

zcat ${DATA_DIR}/${SAMPLE}*.fq*.gz | \
paste - - - - | \
cut -f 1,2 | \
sed 's/^@/>/' | \
sed 's/ /\//' | \
tr "\t" "\n" > ${FASTA_OUT_DIR}/${SAMPLE}.temp.fasta

seqs_fasta=$(grep -c '^>' ${FASTA_OUT_DIR}/${SAMPLE}.temp.fasta)

if [ "$seqs_fasta" != "$seqs_original" ]; then
echo 'WARNING: Number of sequences in fastq and fasta do not match'
fi

date
echo '# Mapping'
blastn \
 -max_target_seqs 1 \
 -db ${DB_BLAST} \
 -outfmt '6 qseqid sseqid pident length qcovhsp qstart qend sstart send evalue' \
 -perc_identity 90 \
 -qcov_hsp_perc 70 \
 -query ${FASTA_OUT_DIR}/${SAMPLE}.temp.fasta \
 -out ${BLAST_OUT_DIR}/${SAMPLE}.blast \
 -num_threads ${NUM_THREADS}

date
echo '# Blast finished'

mtags_map=$(awk '{print $1}' ${BLAST_OUT_DIR}/${SAMPLE}.blast | sort -u | wc -l)

echo '# Take hits'

awk '{print $1}' ${BLAST_OUT_DIR}/${SAMPLE}.blast | sort -u > ${BLAST_OUT_DIR}/${SAMPLE}.hits

date
echo '# Extracting sequences with seqkit'

seqkit \
grep -f ${BLAST_OUT_DIR}/${SAMPLE}.hits \
${FASTA_OUT_DIR}/${SAMPLE}.temp.fasta > ${FASTA_OUT_DIR}/${SAMPLE}.nolabel.fna

mtags_fna=$(grep -c '^>' ${FASTA_OUT_DIR}/${SAMPLE}.nolabel.fna)

if [ "$mtags_map" != "$mtags_fna" ]; then
echo 'WARNING: Total extracted sequences do not match with those in map'
fi

echo '# Remove wrapping and add barcodelabel'

SAMPLE_NOPAIR=$(echo ${SAMPLE} | sed 's/-r[12]//')
# SAMPLE_NOPAIR=$(echo ${SAMPLE} | sed 's/_[12]//')

cat ${FASTA_OUT_DIR}/${SAMPLE}.nolabel.fna | \
  awk '/^>/ {printf("%s%s\t",(N>0?"\n":""),$0);N++;next;} {printf("%s",$0);} END {printf("\n");}' | \
  tr '\t' '\n' | \
  sed "s/>.*/&;barcodelabel=${SAMPLE_NOPAIR};/" \
  > ${FASTA_OUT_DIR}/${SAMPLE}.mtags.fna

mtags_fna_label=$(grep -c '^>' ${FASTA_OUT_DIR}/${SAMPLE}.mtags.fna)

if [ "$mtags_fna" != "$mtags_fna_label" ]; then
echo 'WARNING: Fastas with and without label contain different sequences'
fi

#Removing intermediate files

rm ${FASTA_OUT_DIR}/${SAMPLE}.temp.fasta
rm ${FASTA_OUT_DIR}/${SAMPLE}.nolabel.fna

#Summary

echo "SUMMARY SAMPLE ${SAMPLE}; Initial seqs: $seqs_original; Fasta seqs: $seqs_fasta; mTags retrieved: $mtags_fna_label"
