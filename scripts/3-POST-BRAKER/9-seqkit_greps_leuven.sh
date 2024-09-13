
module load seqkit

TK=lustre/tokeep_leuven

FC=lustre/filters_clean_leuven


mkdir -p ${TK}

mkdir -p ${FC}/filter1
mkdir -p ${FC}/filter2
mkdir -p ${FC}/filter3

for SAMPLE in $(cat data/clean/Leuven_SAGs_sel_74.txt)
do

	awk '{print $1}' lustre/tables_filter_leuven/${SAMPLE}_table6_filter1.tsv | tail -n +2 > ${TK}/${SAMPLE}_filter1_tokeep.txt
	awk '{print $1}' lustre/tables_filter_leuven/${SAMPLE}_table6_filter2.tsv | tail -n +2 > ${TK}/${SAMPLE}_filter2_tokeep.txt
	awk '{print $1}' lustre/tables_filter_leuven/${SAMPLE}_table6_filter3.tsv | tail -n +2 > ${TK}/${SAMPLE}_filter3_tokeep.txt


	seqkit grep -f ${TK}/${SAMPLE}_filter1_tokeep.txt store/Leuven_spades_103/scaffolds/${SAMPLE}_scaffolds.fasta > ${FC}/filter1/${SAMPLE}_filter1_clean.fasta
	seqkit grep -f ${TK}/${SAMPLE}_filter2_tokeep.txt store/Leuven_spades_103/scaffolds/${SAMPLE}_scaffolds.fasta > ${FC}/filter2/${SAMPLE}_filter2_clean.fasta
	seqkit grep -f ${TK}/${SAMPLE}_filter3_tokeep.txt store/Leuven_spades_103/scaffolds/${SAMPLE}_scaffolds.fasta > ${FC}/filter3/${SAMPLE}_filter3_clean.fasta

done

rm ${TK}/*
