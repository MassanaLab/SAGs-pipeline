
W=david_75

OUT_FILE="lustre/${W}_og+3filters_gene_count+50aa_filter.txt"

rm ${OUT_FILE}

HEADER="SAMPLE\tOG_GENES\tPOST_FILTER1_GENES\tPOST_FILTER2_GENES\tPOST_FILTER3_GENES\tFILTER3 >=50aa\tFILTER3 <50aa"

echo -e "$HEADER" > $OUT_FILE


for SAMPLE in $(cat data/clean/${W}.txt | sort);
do

 OG_NUM=$(tail -n +2 lustre/aleix_gtf_${W}_process_out/${SAMPLE}_gtf_processed.txt | wc -l)

 F1_NUM=$(tail -n +2 lustre/filter1_scaffold_gene_link_${W}/${SAMPLE}_filter1_scaffold_gene_link.tsv | wc -l)

 F2_NUM=$(tail -n +2 lustre/filter2_scaffold_gene_link_${W}/${SAMPLE}_filter2_scaffold_gene_link.tsv | wc -l)

 F3_NUM=$(grep -c ">" store/${W}_filter3_final_folders/${SAMPLE}/${SAMPLE}_filter3_genes_hdr.aa)

 F3_50_NUM=$(grep -c ">" lustre/${W}_filter_genes_50/${SAMPLE}_filter3_genes_hdr_filter_50aa.aa)

 RESTA=$((F3_NUM - F3_50_NUM))

 echo -e ${SAMPLE}'\t'${OG_NUM}'\t'${F1_NUM}'\t'${F2_NUM}'\t'${F3_NUM}'\t'${F3_50_NUM}'\t'${RESTA} >> $OUT_FILE

done;
