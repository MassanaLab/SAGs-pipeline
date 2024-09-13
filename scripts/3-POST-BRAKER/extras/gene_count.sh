OUT_FILE="lustre/LEUVEN_61_gene_count.txt"

HEADER="SAMPLE\tGENES"

echo -e "$HEADER" > $OUT_FILE


for SAMPLE in $(ls lustre/braker_LEUVEN/gtf/ | awk -F "_" '{print $1"_"$2}' | sort);
do

 NUM=$(tail -n +2 lustre/aleix_gtf_Leuven_process_out/${SAMPLE}_gtf_processed.txt | wc -l)

  echo -e ${SAMPLE}'\t'${NUM} >> $OUT_FILE

done;
