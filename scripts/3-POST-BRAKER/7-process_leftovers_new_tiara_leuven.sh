W=coass_juliol

FLON=lustre/flon_${W}

TIARA=lustre/qbt_coassembly_filter1000_juliol/tiara

NEW_TIARA=lustre/new_tiara_${W}

rm -r ${FLON}

rm -r ${NEW_TIARA}

mkdir -p ${FLON}

mkdir -p ${NEW_TIARA}


ALEIX=lustre/aleix_gtf_${W}_process_out

SCAFFOLDS=lustre/${W}_filter1000


for SAMPLE in $(cat data/clean/names_${W}.txt)
do

        awk '{print $1}' ${ALEIX}/${SAMPLE}_gtf_processed.txt | tail -n +2 | uniq > ${FLON}/${SAMPLE}_uniq

        grep ">" ${SCAFFOLDS}/${SAMPLE}_scaffolds_filter1000.fasta > ${FLON}/${SAMPLE}_all

        grep -vf ${FLON}/${SAMPLE}_uniq ${FLON}/${SAMPLE}_all | sed 's/>//g' | awk -F '_' '$4 >= 1000 {print $1"_"$2"_"$3"_"$4"_"$5"_"$6}' > ${FLON}/${SAMPLE}_filter_lo_names.txt


        grep -f ${FLON}/${SAMPLE}_filter_lo_names.txt ${TIARA}/${SAMPLE}* > ${NEW_TIARA}/${SAMPLE}_new_tiara.txt


        rm ${FLON}/${SAMPLE}_uniq
        rm ${FLON}/${SAMPLE}_all

done
