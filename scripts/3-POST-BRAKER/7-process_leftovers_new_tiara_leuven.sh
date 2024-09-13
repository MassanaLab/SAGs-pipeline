

FLON=lustre/flon_leuven

TIARA=store/tiara_leuven_74

NEW_TIARA=lustre/new_tiara_leuven


mkdir -p ${FLON}

mkdir -p ${NEW_TIARA}


for SAMPLE in $(cat data/clean/Leuven_SAGs_sel_74.txt)
do

	awk '{print $1}' lustre/aleix_gtf_Leuven_process_out/${SAMPLE}_gtf_processed.txt | tail -n +2 | uniq > ${FLON}/${SAMPLE}_uniq

	grep ">" store/Leuven_spades_103/scaffolds/${SAMPLE}_scaffolds.fasta > ${FLON}/${SAMPLE}_all

	grep -vf ${FLON}/${SAMPLE}_uniq ${FLON}/${SAMPLE}_all | sed 's/>//g' | awk -F '_' '$4 >= 1000 {print $1"_"$2"_"$3"_"$4"_"$5"_"$6}' > ${FLON}/${SAMPLE}_filter_lo_names.txt


	grep -f ${FLON}/${SAMPLE}_filter_lo_names.txt ${TIARA}/${SAMPLE}* > ${NEW_TIARA}/${SAMPLE}_new_tiara.txt


	rm ${FLON}/${SAMPLE}_uniq
	rm ${FLON}/${SAMPLE}_all

done


#module load seqkit

#seqkit grep -f ${PLO}/${SAMPLE}_filter_lo_names.txt store/spades_essentials_252/scaffolds/${SAMPLE}_K127_scaffolds.fasta > ${PLO}/${SAMPLE}_lo.fasta

#cat lustre/tables_test_filter/${SAMPLE}_filter1_clean.fasta ${PLO}/${SAMPLE}_lo.fasta > ${PLO}/${SAMPLE}_filter1_all_scaff.fasta

#cat lustre/tables_test_filter/${SAMPLE}_filter2_clean.fasta ${PLO}/${SAMPLE}_lo.fasta > ${PLO}/${SAMPLE}_filter2_all_scaff.fasta

#cat lustre/tables_test_filter/${SAMPLE}_filter3_clean.fasta ${PLO}/${SAMPLE}_lo.fasta > ${PLO}/${SAMPLE}_filter3_all_scaff.fasta


# rm ${PLO}/${SAMPLE}_filter_lo_names.txt
# rm ${PLO}/${SAMPLE}_lo.fasta
