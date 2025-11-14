module load seqkit

W=coass_juliol

TK=lustre/tokeep_${W}

FC=lustre/filters_clean_${W}


mkdir -p ${TK}

mkdir -p ${FC}/filter1
mkdir -p ${FC}/filter2
mkdir -p ${FC}/filter3


SC=lustre/aleix_gff_process_big2_${W}/assemblies1_clean

TOTAL=$(cat data/clean/names_${W}.txt | wc -l)

i=1


for SAMPLE in $(cat data/clean/names_${W}.txt)
do

        echo "Processing $i/$TOTAL: $SAMPLE"

        awk '{print $1}' lustre/tables_filter_${W}/${SAMPLE}_table6_filter1.tsv | tail -n +2 > ${TK}/${SAMPLE}_filter1_tokeep.txt
        awk '{print $1}' lustre/tables_filter_${W}/${SAMPLE}_table6_filter2.tsv | tail -n +2 > ${TK}/${SAMPLE}_filter2_tokeep.txt
        awk '{print $1}' lustre/tables_filter_${W}/${SAMPLE}_table6_filter3.tsv | tail -n +2 > ${TK}/${SAMPLE}_filter3_tokeep.txt


        seqkit grep -f ${TK}/${SAMPLE}_filter1_tokeep.txt ${SC}/${SAMPLE}.fasta > ${FC}/filter1/${SAMPLE}_filter1_clean.fasta
        seqkit grep -f ${TK}/${SAMPLE}_filter2_tokeep.txt ${SC}/${SAMPLE}.fasta > ${FC}/filter2/${SAMPLE}_filter2_clean.fasta
        seqkit grep -f ${TK}/${SAMPLE}_filter3_tokeep.txt ${SC}/${SAMPLE}.fasta > ${FC}/filter3/${SAMPLE}_filter3_clean.fasta

        i=$((i + 1))

done

rm ${TK}/*
